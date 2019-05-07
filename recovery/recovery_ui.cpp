/*
 * Copyright (C) 2016 GlobalLogic
 * 
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

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <cutils/android_reboot.h>
#include <cutils/properties.h>

#include "recovery_ui/device.h"
#include "recovery_ui/screen_ui.h"
#include "install/install.h"
#include "bootloader.h"

extern RecoveryUI* ui;

/* ------------------------------------------------------------------ */
#define HYPER_CA_PATH           "/sbin/hyper_ca"
#define HYPER_CA                "hyper_ca"

#define IPL_ERASE_TIMEOUT        15 /* ... */
#define TEE_SUPPLICANT_TIMEOUT   10 /* ... */

class RenesasUpdateIpl
{
public:

    bool IsTeeSupplicantRunning(void)
    {
        char tee_supp_status[PROPERTY_VALUE_MAX];

        for (int i = 0; i< TEE_SUPPLICANT_TIMEOUT; i++) {

            property_get("init.svc.tee_supplicant", tee_supp_status, "");

            if (strcmp(tee_supp_status, "running") == 0) {
                return true;
            }
            sleep(1);
        }
        return false;
    }

    int EraseSSData(void)
    {
        ui->Print("Erasing Secure Storage..\n");
        pid_t child = fork();
        if (child == 0) {
            execl(HYPER_CA_PATH, HYPER_CA, "-e", "SSTDATA", NULL);
            /* Should not return */
            return INSTALL_ERROR;
        }

        int pid_status;
        for (int i = 0; i < IPL_ERASE_TIMEOUT; ++i) {
            if (waitpid(child, &pid_status, WNOHANG) != 0) {
                break;
            }
            ui->Print(".");
            sleep(1);
        }

        ui->Print("\n");

        if (!WIFEXITED(pid_status) || WEXITSTATUS(pid_status) != 0) {
            ui->Print("Erase Error (%d).\n", WEXITSTATUS (pid_status));
            return INSTALL_ERROR;
        }

        ui->Print("SSTDATA Erased\n");
        return INSTALL_SUCCESS;
    }

    void SetRebootBL(void)
    {
        reboot_bl = true;
    }

    bool GetRebootBL(void)
    {
        return reboot_bl;
    }

private:
    bool reboot_bl = false;
};

class RenesasDevice : public Device, private RenesasUpdateIpl {
public:
    RenesasDevice(RecoveryUI* ui) : Device(ui) { }

    virtual void StartRecovery(void) {
        std::string err;

        /* Checking for bootloader options */
        struct bootloader_message boot;
        memset(&boot, 0, sizeof(boot));

        if(!read_bootloader_message(&boot, &err)) {
            return; /* Can't get bootloder message, skip options checking */
        }

        boot.recovery[sizeof(boot.recovery) - 1] = '\0';  /* Ensure termination */

        const char *arg1 = strtok(boot.recovery, "\n");
        const char *arg2 = strtok(NULL, "\n");
        const char *arg3 = strtok(NULL, "\n");

        /* Ensure that argument for recovery */
        if (arg1 != NULL && !strcmp(arg1, "recovery")) {

            if (arg2 != NULL && !strcmp(arg2, "--wipe_data")) {
                if (arg3 != NULL && !strcmp(arg3, "--reboot_bl")) {
                    SetRebootBL();
                }
            } else if (arg2 != NULL && !strcmp(arg2, "--erase_sstdata")) {
		ui->ShowText(true);
		ui->Print("Erase optee secure store ...\n");
		bool bSuccess = EraseSSData() == INSTALL_SUCCESS;
                memset(&boot, 0, sizeof(boot));
                strcpy(boot.status, (bSuccess ? "OKAY" : "FAILED!"));
                write_bootloader_message(boot, &err);
                property_set(ANDROID_RB_PROPERTY, "reboot,bootloader");
            }
        }
    };

    virtual bool PostWipeData(void) {
        if (GetRebootBL())
            property_set(ANDROID_RB_PROPERTY, "reboot,bootloader");

         /*We are not suppose to return from this..*/
         return true;
    }
};

Device* make_device() {
    return new RenesasDevice(new ScreenRecoveryUI);
}
