/*
 * Copyright (c) 2021-2023 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "n_func_arg.h"

using namespace std;

NFuncArg::NFuncArg(napi_env env, napi_callback_info info) : env_(env), info_(info) {}

NFuncArg::~NFuncArg() {}

void NFuncArg::SetArgc(size_t argc)
{
    argc_ = argc;
}

void NFuncArg::SetThisVar(napi_value thisVar)
{
    thisVar_ = thisVar;
}

size_t NFuncArg::GetArgc(void) const
{
    return argc_;
}

void NFuncArg::SetMaxArgc(size_t maxArgc)
{
    maxArgc_ = maxArgc;
}

size_t NFuncArg::GetMaxArgc(void) const
{
    return maxArgc_;
}

napi_value NFuncArg::GetThisVar(void) const
{
    return thisVar_;
}

napi_value NFuncArg::GetArg(size_t argPos) const
{
    return (argPos < GetArgc()) ? argv_[argPos] : nullptr;
}

napi_value NFuncArg::operator[](size_t argPos) const
{
    return GetArg(argPos);
}

bool NFuncArg::InitArgs(std::function<bool()> argcChecker)
{
    SetArgc(0);
    argv_.reset();

    size_t argc;
    napi_value thisVar;
    napi_status status = napi_get_cb_info(env_, info_, &argc, nullptr, &thisVar, nullptr);
    if (status != napi_ok) {
        return false;
    }
    if (argc) {
        argv_ = make_unique<napi_value[]>(argc);
        status = napi_get_cb_info(env_, info_, &argc, argv_.get(), &thisVar, nullptr);
        if (status != napi_ok) {
            return false;
        }
    }
    SetArgc(argc);
    SetThisVar(thisVar);
    SetMaxArgc(argc);
    return argcChecker();
}

bool NFuncArg::InitArgs(size_t argc)
{
    return InitArgs([argc, this]() {
        size_t realArgc = GetArgc();
        if (argc != realArgc) {
            return false;
        }
        return true;
    });
}

bool NFuncArg::InitArgs(size_t minArgc, size_t maxArgc)
{
    return InitArgs([minArgc, maxArgc, this]() {
        size_t realArgc = GetArgc();
        if (minArgc > realArgc || maxArgc < realArgc) {
            return false;
        }
        SetMaxArgc(maxArgc);
        return true;
    });
}
