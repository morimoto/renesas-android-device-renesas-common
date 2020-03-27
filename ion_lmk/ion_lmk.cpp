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

static const std::string DevION =  "/dev/ion";
static const std::string DevION_LMK = "/dev/rcar_ion_lmk";

/* Critical processes, that can't be killed */
static const std::vector<std::string> BannedProcesses = {
    "system_server",
    "surfaceflinger",
    /* "ndroid" - isn't typo, the name of process cut to 16 chars by system */
    "ndroid.systemui",
    "android.hardwar",
    "car.carlauncher",
};

static bool IsBannedProcess(std::string name) {
    auto iter = std::find(BannedProcesses.begin(), BannedProcesses.end(), name);
    return iter != BannedProcesses.end();
}

static void PrintNonTrackedPorcessesList() {
    ALOGI("List of processes, which shouldn't be tracked (banned list):");
    for (size_t i = 0; i < BannedProcesses.size(); i++) {
        ALOGI("%s", BannedProcesses[i].c_str());
    }
}

static int GetIONConsumers(std::vector<ion_proc_info> &consumers) {
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

    consumers.resize(consumers_cnt);
    buf.size = consumers_cnt;
    buf.info = &consumers[0];

    ret = ioctl(fd, ION_IOC_GET_ION_CONSUMERS_INFO, &buf);
    if (ret) {
        ALOGE(" (%d): failed to get ION_IOC_GET_ION_CONSUMERS_INFO\n", ret);
    }

close_fd:
    close(fd);

    return ret;
}

/*
 * Kills process with the biggest ION memory consumption.
 */
static void KillProcesses() {
    std::vector<ion_proc_info> consumers;
    /* PID, which should be killed */
    int k_pid = -1;
    size_t k_idx = 0;

    if (GetIONConsumers(consumers))
        return;

    for (size_t i = 0; i < consumers.size(); ++i) {
        if (!IsBannedProcess(consumers[i].comm) && consumers[i].mem > consumers[k_idx].mem) {
            k_idx = i;
            k_pid = consumers[i].pid;
        }
    }

    /* If k_pid is still -1, that service hasn't detected any non-banned process to kill */
    if (k_pid != -1) {
        int ret = kill(k_pid, SIGKILL);
        ALOGI("Proccess %s %d uses %llu bytes of ION memory and should be killed (returned %d)\n",
            consumers[k_idx].comm, k_pid, consumers[k_idx].mem, ret);
        if (ret) {
            ALOGI("errno %d\n", errno);
        }
    }
}

/*
 * RCAR_GET_OOM_EVENT will be blocked until ION out of memory
 * has been occurred or the threshold has been crossed.
 * This prevents CPU overuse.
 */
static int GetIONEventOOM(ion_oom_event &oom) {
    struct ion_custom_data data;
    int fd;
    int ret = -1;

    fd = open(DevION.c_str(), O_RDWR);
    if (fd == -1) {
        ALOGE("Failed to open %s\n", DevION.c_str());
        return -1;
    }

    data.cmd = RCAR_GET_OOM_EVENT;
    data.arg = reinterpret_cast<unsigned long>(&oom);
    ret = ioctl(fd, RCAR_ION_CUSTOM, &data);
    if (ret) {
        ALOGE("ioctl (ION_IOC_GET_OOM_EVENT) failed with err (%d): \n", ret);
        goto close_fd;
    }

    ALOGI("GOT OOM Event: %d available = %llu\n", oom.oom_event, oom.memory_available);

close_fd:
    close(fd);

    return ret;
}

int main(int argc, char* argv[]) {
    struct option longopts[] = { { "threshold", required_argument, nullptr, 't' },
                                { 0, 0, nullptr, 0 } };
    int opt;
    uint64_t threshold = 0;
    while ((opt = getopt_long(argc, argv, "t:ul", longopts, nullptr)) != -1) {
        switch (opt) {
            case 't':
                if (optarg) {
                    threshold = std::strtoul(optarg, nullptr, 10);
                    /* Convert to MBytes */
                    threshold *= 1024 * 1024;
                }
                break;
            default:
                break;
        }
    }
    PrintNonTrackedPorcessesList();

    ion_oom_event oomEvent;

    while (true) {
        memset(&oomEvent, 0, sizeof(oomEvent));
        oomEvent.oom_threshold = threshold;

        if (GetIONEventOOM(oomEvent))
            exit(EXIT_FAILURE);

        KillProcesses();

        /* Sleep 5 second after SIGKILL was sent */
        std::this_thread::sleep_for(std::chrono::seconds(5));
    }

    return 0;
}
