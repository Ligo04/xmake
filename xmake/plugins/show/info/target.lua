--!A cross-platform build utility based on Lua
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
--
-- Copyright (C) 2015-present, TBOOX Open Source Group.
--
-- @author      ruki
-- @file        target.lua
--

-- imports
import("core.base.option")
import("core.base.hashset")
import("core.project.config")
import("core.project.project")
import("core.language.language")

-- get source info string
function _get_sourceinfo_str(target, name, item)
    local sourceinfo = target:sourceinfo(name, item)
    if sourceinfo then
        return string.format(" ${dim}(%s:%s)${clear}", sourceinfo.file or "", sourceinfo.line or -1)
    end
    return ""
end

-- show target information
function _show_target(target)
    print("The information of target(%s):", target:name())
    cprint("    ${color.dump.string}at${clear}: %s", path.join(target:scriptdir(), "xmake.lua"))
    cprint("    ${color.dump.string}kind${clear}: %s", target:kind())
    cprint("    ${color.dump.string}targetfile${clear}: %s", target:targetfile())
    local deps = target:get("deps")
    if deps then
        cprint("    ${color.dump.string}deps${clear}:")
        for _, dep in ipairs(deps) do
            cprint("      ${color.dump.reference}->${clear} %s%s", dep, _get_sourceinfo_str(target, "deps", dep))
        end
    end
    local rules = target:get("rules")
    if rules then
        cprint("    ${color.dump.string}rules${clear}:")
        for _, value in ipairs(rules) do
            cprint("      ${color.dump.reference}->${clear} %s%s", value, _get_sourceinfo_str(target, "rules", value))
        end
    end
    local options = {}
    for _, opt in ipairs(target:get("options")) do
        if not opt:startswith("__") then
            table.insert(options, opt)
        end
    end
    if #options > 0 then
        cprint("    ${color.dump.string}options${clear}:")
        for _, value in ipairs(options) do
            cprint("      ${color.dump.reference}->${clear} %s%s", value, _get_sourceinfo_str(target, "options", value))
        end
    end
    local packages = target:get("packages")
    if packages then
        cprint("    ${color.dump.string}packages${clear}:")
        for _, value in ipairs(packages) do
            cprint("      ${color.dump.reference}->${clear} %s%s", value, _get_sourceinfo_str(target, "packages", value))
        end
    end
    for _, apiname in ipairs(table.join(language.apis().values, language.apis().paths)) do
        if apiname:startswith("target.") then
            local valuename = apiname:split('.add_', {plain = true})[2]
            if valuename then
                local values = target:get(valuename)
                local values_from_deps = target:get_from_deps(valuename)
                local values_from_opts = target:get_from_opts(valuename)
                local values_from_pkgs = target:get_from_pkgs(valuename)
                values = table.unique(table.join(values or {}, values_from_deps or {}, values_from_opts or {}, values_from_pkgs or {}))
                if #values > 0 then
                    cprint("    ${color.dump.string}%s${clear}:", valuename)
                    for _, value in ipairs(values) do
                        cprint("      ${color.dump.reference}->${clear} %s%s", value, _get_sourceinfo_str(target, valuename, value))
                    end
                end
            end
        end
    end
    local files = target:get("files")
    if files then
        cprint("    ${color.dump.string}files${clear}:")
        for _, file in ipairs(files) do
            cprint("      ${color.dump.reference}->${clear} %s%s", file, _get_sourceinfo_str(target, "files", file))
        end
    end
    local sourcekinds = hashset.new()
    for _, sourcebatch in pairs(target:sourcebatches()) do
        if sourcebatch.sourcekind then
            sourcekinds:insert(sourcebatch.sourcekind)
        end
    end
    for _, sourcekind in sourcekinds:keys() do
        local compinst = target:compiler(sourcekind)
        if compinst then
            cprint("    ${color.dump.string}compflags (%s)${clear}: %s", sourcekind, compinst:program())
            cprint("      ${color.dump.reference}->${clear} %s", os.args(compinst:compflags({target = target})))
        end
    end
    local linker = target:linker()
    if linker then
        cprint("    ${color.dump.string}linkflags (%s)${clear}: %s", linker:kind(), linker:program())
        cprint("      ${color.dump.reference}->${clear} %s", os.args(linker:linkflags({target = target})))
    end
end

function main(name)

    -- get target
    config.load()
    local target = assert(project.target(name), "target(%s) not found!", name)

    -- show target information
    _show_target(target)
end
