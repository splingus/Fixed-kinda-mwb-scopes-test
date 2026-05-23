if SERVER then
    AddCSLuaFile()
end
print("trmbase_att_load")
BASE_TRM_ATTS = BASE_TRM_ATTS or {}
TRM_BASE_REF = 69

local function LoadAttachmentStats(path, fileName)
    local name = string.Replace(fileName, ".lua", "")
    local fullPath = path .. "/" .. fileName

    if SERVER then
        AddCSLuaFile(fullPath)
    end

    local func = CompileFile(fullPath)
    if not func then
        print("[TRMAtt] Failed to load:", fullPath)
        return
    end

    ATTACHMENT = {}
    ATTACHMENT.ClassName = name
    ATTACHMENT.Folder = path

    func()

    BASE_TRM_ATTS[name] = BASE_TRM_ATTS[name] or {}
    table.Merge(BASE_TRM_ATTS[name], table.Copy(ATTACHMENT))
end



local function LoadAttachments(path)
    local files, folders = file.Find(path .. "/*", "LUA")
    print("load!")
    for _, fileName in ipairs(files) do
        if string.EndsWith(fileName, ".lua") then
            LoadAttachmentStats(path, fileName)
        end
    end

    for _, folderName in ipairs(folders) do
        LoadAttachments(path .. "/" .. folderName)
    end
end

LoadAttachments("trmbase/attachments")



local function inherit(current, base)
    for k, v in pairs(base) do
        if not istable(v) then
            if current[k] == nil then
                current[k] = v
            end
        else
            if current[k] == nil then
                current[k] = {}
            end
            inherit(current[k], v)
        end
    end
end

function BASE_TRM_ATTS.Inherit(att)
    local baseClass = BASE_TRM_ATTS[att.Base]
    while baseClass do
        inherit(att, baseClass)
        baseClass = BASE_TRM_ATTS[baseClass.Base]
    end
end

local function finishAttachments()
    for name, att in pairs(BASE_TRM_ATTS) do
        if type(att) ~= "table" then
            print("[TRMAtt] Skipping non-table:", name, type(att))
            continue
        end
        if att.Base then
            BASE_TRM_ATTS.Inherit(att)
        end
    end
end
finishAttachments()


hook.Add("OnReloaded", "TRMBASE_ATT_RELOAD", function()
    LoadAttachments("trmbase/attachments")
    finishAttachments()
end)

-- 查看所有已加载配件
concommand.Add("trm_list_atts", function()
    PrintTable(BASE_TRM_ATTS)
end)

-- 查看某个配件的详细信息
concommand.Add("trm_att_info", function(ply, cmd, args)
    local name = args[1]
    if not name then
        print("Usage: trm_att_info <attachment_name>")
        return
    end
    local att = BASE_TRM_ATTS[name]
    if att then
        PrintTable(att)
    else
        print("Attachment not found: " .. name)
    end
end)

-- 重新加载所有配件（开发用）
concommand.Add("trm_reload_atts", function()
    LoadAttachments("trmbase/attachments")
    finishAttachments()
end)
