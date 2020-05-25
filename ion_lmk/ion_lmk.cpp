/*
* Copyright (C) 2020 GlobalLogic
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include <dirent.h>
#include <getopt.h>
#include <inttypes.h>
#include <stdlib.h>
#include <unistd.h>

#include <sys/stat.h>
#include <sys/types.h>

#include <linux/input.h>
#include <fcntl.h>
#include <stdio.h>
#include <errno.h>

#include <sys/ioctl.h>
#include <sys/mman.h>

#include <string>
#include <vector>
#include <thread>
#include <chrono>

#include <android-base/stringprintf.h>
#include <log/log.h>

#include <uapi/linux/rcar_ion.h>
#include <uapi/linux/rcar_ion_lmk.h>

#ifdef LOG_TAG
#undef LOG_TAG
#endif

#define LOG_TAG "Renesas-ION-LMK"
#define BYTES_TO_MB(x) ((x) / (1024 * 1024))

struct ThresholdRange {
    size_t mMax;
    size_t mCurr;
    size_t mMin;
};

class ION_LMK {
    public:
        ION_LMK(const ThresholdRange &threshold) :
            mThreshold(threshold) {};
        void Loop(size_t delay);
        void PrintNonTrackedPorcessesList() const;

    private:
        bool IsBannedProcess(const std::string &) const;
        bool IsBackground(const ion_proc_info &) const;
        bool HasBackgroundConsumer() const;

        int GetIONConsumers();
        int GetIONEventOOM();
        void RemovemBannedProcesses();
        void KillProcesses();
        void AdbjustThreshold();

        ThresholdRange mThreshold;
        size_t mFreedMemory;
        ion_oom_event mOOM_Event;
        std::vector<ion_proc_info> mConsumers;

        const std::string DevION =  "/dev/ion";
        const std::string DevION_LMK = "/dev/rcar_ion_lmk";
        /* Critical processes, that can't be killed */
        const std::vector<std::string> mBannedProcesses = {
            "system_server",
            "surfaceflinger",
            /* "ndroid" - isn't typo, the name of process cut to 16 chars by system */
            "ndroid.systemui",
            /* Exclude the most HALs (hwcomposer and etc)*/
            "android.hardwar",
            "car.carlauncher",
            "allocator@",
        };
};

/* The method matches process names with mBannedProcesses patterns */
bool ION_LMK::IsBannedProcess(const std::string &name) const {
    for (size_t i = 0; i < mBannedProcesses.size(); ++i) {
        size_t minLength = name.size() < mBannedProcesses[i].size()
            ? name.size() : mBannedProcesses[i].size();
        if (!std::strncmp(name.c_str(), mBannedProcesses[i].c_str(), minLength)) {
            return true;
        }
    }

    return false;
}

void ION_LMK::PrintNonTrackedPorcessesList() const {
    ALOGI("List of processes, which shouldn't be tracked (banned list):");
    for (size_t i = 0; i < mBannedProcesses.size(); ++i) {
        ALOGI("%s", mBannedProcesses[i].c_str());
    }
}

int ION_LMK::GetIONConsumers() {
    int ret;
    int fd;
    size_t consumers_cnt = 0;
    ion_proc_info_buf buf;

    fd = open(DevION_LMK.c_str(), O_RDWR);
    if (fd == -1) {
        ALOGE("Failed to open %s\n", DevION_LMK.c_str());
        return -1;
    }

    ret = ioctl(fd, ION_IOC_GET_ION_CONSUMERS_СNТR, &consumers_cnt);
    if (ret) {
        ALOGE(" (%d): failed to get ION_IOC_GET_ION_CONSUMERS_СNТR\n", ret);
        goto close_fd;
    }

    if (!consumers_cnt) {
        ALOGD("There is no non-banned ION memory consumers");
        goto close_fd;
    }

    mConsumers.resize(consumers_cnt);
    buf.size = consumers_cnt;
    buf.info = &mConsumers[0];

    ret = ioctl(fd, ION_IOC_GET_ION_CONSUMERS_INFO, &buf);
    if (ret) {
        ALOGE(" (%d): failed to get ION_IOC_GET_ION_CONSUMERS_INFO\n", ret);
    }

close_fd:
    close(fd);

    return ret;
}

/*
 * RCAR_GET_OOM_EVENT will be blocked until ION out of memory
 * has been occurred or the threshold has been crossed.
 * This prevents CPU overuse.
 */
int ION_LMK::GetIONEventOOM() {
    struct ion_custom_data data;
    int fd;
    int ret = -1;

    fd = open(DevION.c_str(), O_RDWR);
    if (fd == -1) {
        ALOGE("Failed to open %s\n", DevION.c_str());
        return -1;
    }

    data.cmd = RCAR_GET_OOM_EVENT;
    data.arg = reinterpret_cast<unsigned long>(&mOOM_Event);
    ret = ioctl(fd, RCAR_ION_CUSTOM, &data);
    if (ret) {
        ALOGE("ioctl (ION_IOC_GET_OOM_EVENT) failed with err (%d): \n", ret);
        goto close_fd;
    }

    ALOGI("GOT OOM Event: %d available = %llu\n", mOOM_Event.oom_event, mOOM_Event.memory_available);

close_fd:
    close(fd);

    return ret;
}

bool ION_LMK::IsBackground(const ion_proc_info &info) const {
    return !strncmp(info.state, "/background", strlen("/background"));
}

bool ION_LMK::HasBackgroundConsumer() const {
    for (size_t i = 0; i < mConsumers.size(); ++i) {
        if (IsBackground(mConsumers[i])) {
            return true;
        }
    }
    return false;
}

void ION_LMK::RemovemBannedProcesses() {
    auto it = mConsumers.begin();
    while (it != mConsumers.end()) {
        if (IsBannedProcess(it->comm)) {
            it = mConsumers.erase(it);
        } else {
            ++it;
        }
    }
}

/*
 * Kills process with the biggest ION memory consumption.
 */
void ION_LMK::KillProcesses() {
    bool has_background_consumer;
    /* PID, which should be killed */
    int k_pid = -1;
    size_t k_idx = 0;
    size_t proc_mem = 0;

    mFreedMemory = 0;

    if (GetIONConsumers()) {
        return;
    }

    RemovemBannedProcesses();

    has_background_consumer = HasBackgroundConsumer();
    /*
     * Reduce the threshold if just threshold has been crossed, but mThreshold.mMin
     * hasn't been reached and we don't have backround processes to kill.
     */
    if ((mOOM_Event.oom_event == OOM_THRESHOLD) && !has_background_consumer &&
        (mOOM_Event.memory_available > mThreshold.mMin)) {
        return;
    }

    for (size_t i = 0; i < mConsumers.size(); ++i) {
        /* Processes in background state is preferable candidate */
        if (has_background_consumer && !IsBackground(mConsumers[i])) {
            continue;
        }

        if (mConsumers[i].mem > proc_mem) {
            proc_mem = mConsumers[k_idx].mem;
            k_idx = i;
            k_pid = mConsumers[i].pid;
        }
    }

    /* If k_pid is still -1, that service hasn't detected any non-banned process to kill */
    if (k_pid != -1) {
        int ret = kill(k_pid, SIGKILL);
        ALOGI("Proccess (state = %s) %s %d uses %llu bytes of ION memory\n",
            mConsumers[k_idx].state, mConsumers[k_idx].comm, k_pid, mConsumers[k_idx].mem);
        ALOGI("SIGKILL has been sent to %s (result: %s)\n", mConsumers[k_idx].comm, ret ? "FAILED" : "OK");
        if (ret) {
            ALOGI("errno %d\n", errno);
            return;
        }
        mFreedMemory = mConsumers[k_idx].mem;
    }
}

void ION_LMK::AdbjustThreshold() {
    size_t aval = mOOM_Event.memory_available;
    uint64_t new_threshold;

    if (!mFreedMemory) {
        new_threshold = mThreshold.mMin + (mThreshold.mCurr - mThreshold.mMin) / 2;
        /*
         * If new threshold less then 10 per cent from difference
         * between max and min, than assign min threshold
         */
        if (new_threshold <= (mThreshold.mMin + (mThreshold.mMax - mThreshold.mMin) / 10)) {
            new_threshold = mThreshold.mMin;
        }

        mThreshold.mCurr = new_threshold;
        return;
    }

    if ((aval + mFreedMemory) > mThreshold.mMax) {
        new_threshold = mThreshold.mMax;
    } else {
        /* Restore value, which was before the reducing */
        new_threshold = (mThreshold.mCurr - mThreshold.mMin) * 2 + mThreshold.mMin;
        mThreshold.mCurr = new_threshold;
    }
    mThreshold.mCurr = new_threshold;
}

void ION_LMK::Loop(size_t delay) {
    memset(&mOOM_Event, 0, sizeof(mOOM_Event));
    if (mThreshold.mMin > mThreshold.mMax) {
        ALOGI("Min threshold is bigger then max. Set max threshold equals min (%lu)\n", mThreshold.mMin);
        mThreshold.mMax = mThreshold.mMin;
    }
    mThreshold.mCurr = mThreshold.mMax;
    mOOM_Event.oom_threshold = mThreshold.mCurr;

    while (true) {
        ALOGI("Set threshold to %lu MB\n", BYTES_TO_MB(mThreshold.mCurr));

        if (GetIONEventOOM())
            exit(EXIT_FAILURE);

        KillProcesses();
        AdbjustThreshold();
        memset(&mOOM_Event, 0, sizeof(mOOM_Event));
        mOOM_Event.oom_threshold = mThreshold.mCurr;

        /* Wait a few seconds until OS kills the process */
        if (mFreedMemory) {
            std::this_thread::sleep_for(std::chrono::seconds(delay));
        }
    }
}

int main(int argc, char* argv[]) {
    struct option longopts[] = { { "threshold", required_argument, nullptr, 't' },
                                 { "min_threshold", required_argument, nullptr, 'm' },
                                 { 0, 0, nullptr, 0 } };
    int opt;
    ThresholdRange threshold;

    while ((opt = getopt_long(argc, argv, "t:m:", longopts, nullptr)) != -1) {
        switch (opt) {
            case 't':
                if (optarg) {
                    threshold.mMax = std::strtoul(optarg, nullptr, 10);
                    /* Convert to MBytes */
                    threshold.mMax *= 1024 * 1024;
                }
                break;
            case 'm':
                if (optarg) {
                    threshold.mMin = std::strtoul(optarg, nullptr, 10);
                    /* Convert to MBytes */
                    threshold.mMin *= 1024 * 1024;
                }
                break;
            default:
                break;
        }
    }

    ION_LMK lmk(threshold);

    lmk.PrintNonTrackedPorcessesList();
    lmk.Loop(1);

    return 0;
}
