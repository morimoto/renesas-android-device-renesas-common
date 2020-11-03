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

package hal_defaults

import (
    "android/soong/android"
    "android/soong/cc"
    "github.com/google/blueprint/proptools"
)

func halDefaults(ctx android.LoadHookContext) {
    const envName = "TARGET_BUILD_VARIANT"

    type props struct {
        Cppflags      []string
        Sanitize      struct{
            Never     *bool
            Undefined *bool
        }
        Strip         struct{
            None      *bool
        }
    }

    p := &props{}

    switch ctx.AConfig().Getenv(envName) {
    case "userdebug", "eng":
        p.Cppflags = append(p.Cppflags, "-O0")
        p.Sanitize.Never = proptools.BoolPtr(false)
        p.Sanitize.Undefined = proptools.BoolPtr(true)
        p.Strip.None = proptools.BoolPtr(true)
    default: //for user build
        p.Cppflags = append(p.Cppflags, "-O2")
        p.Sanitize.Never = proptools.BoolPtr(true)
        p.Sanitize.Undefined = proptools.BoolPtr(false)
        p.Strip.None = proptools.BoolPtr(false)
    }

    ctx.AppendProperties(p)
}

func init() {
    android.RegisterModuleType("hal_defaults", HalDefaultsFactory)
}

func HalDefaultsFactory() android.Module {
    module := cc.DefaultsFactory()
    android.AddLoadHook(module, halDefaults)

    return module
}
