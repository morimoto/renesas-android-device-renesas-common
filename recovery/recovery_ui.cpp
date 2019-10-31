/*
 * Copyright (C) 2019 GlobalLogic
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

#include "recovery_ui/device.h"
#include "recovery_ui/screen_ui.h"
#include "recovery_ui/stub_ui.h"
#include "minui/minui.h"
#include <xf86drm.h>
#include <xf86drmMode.h>

static bool isDisplayConnected() {
    const int drmFd = drmOpen("rcar-du", nullptr);

    if (drmFd < 0) {
        return false;
    }

    drmModeRes* const resources = drmModeGetResources(drmFd);

    if (!resources) {
        return false;
    }

    bool isConnected = false;
    for (int32_t i = 0; i < resources->count_connectors && !isConnected; ++i) {
        drmModeConnector* const connector = drmModeGetConnector(drmFd, resources->connectors[i]);
        if (connector) {
            if (connector->connection == DRM_MODE_CONNECTED) {
                isConnected = true;
            }
            drmModeFreeConnector(connector);
        }
    }

    drmModeFreeResources(resources);
    close(drmFd);
    return isConnected;
}

/*
*We need this custom UI to properly handle fastboot/recovery commands
*when no monitor connected. Otherwise default Stub UI returns immidiately
*from ShowMenu and this leads to the board reboot.
*/
class RenesasRecoveryUI : public StubRecoveryUI {
public:
    size_t ShowMenu(const std::vector<std::string>& /* headers */,
                            const std::vector<std::string>& /* items */,
                            size_t initial_selection,
                            bool /* menu_only */,
                            const std::function<int(int, bool)>&
                            /* key_handler */) override {

        /*
        * Since we have no screen, and no menu, the only way to return from
        * here is to press and hold the POWER button. This is handled by
        * default UI event handler.
        */
        FlushKeys();
        int key = WaitKey();
        if (key == static_cast<int>(KeyError::INTERRUPTED)) {
            return static_cast<size_t>(KeyError::INTERRUPTED);
        }
        if (key == static_cast<int>(KeyError::TIMED_OUT)) {
            return static_cast<size_t>(KeyError::TIMED_OUT);
        }
        return initial_selection;
    }
};

Device* make_device() {
    Device* device = new Device(new ScreenRecoveryUI);

    if (!::isDisplayConnected()) {
        /*
        * Replace UI with our stub if no monitor connected or something
        * wrong with graphics;
        */
        device->ResetUI(new RenesasRecoveryUI());
    }
    return device;
}
