# TRM Attachment Menu Lua Bundle

This bundle contains the Lua files from the base add-on only:

`trm_weapon_base_scope_fix/lua`

The weapon packs for M4 and VEL/MP7 were used only as references for slot names, categories, bones, and attachment behavior. They are not included in this bundle.

## Main File

The attachment menu work is mainly in:

`lua/weapons/trm_gun_base/modules/client/cl_attachments.lua`

That file registers the menu panel:

`vgui.Register("TRM_AttachMenu", PANEL, "DFrame")`

The menu opens from:

`+trmbase_customize`

## How The Attachment Menu Works

The menu is a full-screen Derma frame with a translucent overlay. The goal is to keep the player aware of the world while showing a separate weapon preview area.

The weapon preview uses `DModelPanel`. The panel displays the current weapon model and keeps the weapon isolated inside its own semi-transparent preview box. The player can drag the preview to rotate it and use the mouse wheel to zoom.

Attachment slots are no longer drawn as pointer lines. The earlier line approach was removed because viewmodel and worldmodel attachment points do not reliably line up with what the player sees in the menu. Instead, every slot appears in a bottom strip under the weapon preview, similar to a modern weapon customization UI.

Each bottom slot button represents one entry from:

`SWEP.Attachments`

Clicking a slot changes `self.m_Slot`, then calls:

`RefreshAttList()`

That rebuilds the right-side list so it only shows attachments matching the selected slot category. The filter is handled by `GetAttachmentsForSlot(slot)`, which compares the slot category against `BASE_TRM_ATTS`.

When the player clicks an attachment button, `AddAttButton()` updates the local selected attachment immediately, then calls:

`weapon:SendAttachmentToServer(slotKey, id)`

The server applies the attachment through the existing TRM Base network path. The client also refreshes the preview and the attachment list.

## Preview Updates

The preview uses the same attachment data as the weapon:

- selected attachment class
- attachment model
- bonemerge setting
- slot bone
- slot position/angle
- attachment position/angle
- bodygroups

When an attachment is selected, `RefreshPreview()` removes old preview attachment models and rebuilds the preview using clientside models. This is separate from the actual weapon entity, so the menu can show live attachment changes without needing to alter the player view directly.

## Stats Panel

The stats panel reads the base weapon data and simulated attachment changes. It shows:

- damage
- clip size
- RPM
- spread
- aim time
- recoil

The stats are built through `BuildStats()`. It copies the weapon stat tables, applies selected attachment stat changes, then draws comparison bars.

## Files Included

This archive includes all Lua files from the base add-on. It does not include models, materials, sounds, or weapon packs. This keeps the file small and focused on code review/documentation.

## 中文说明

这个压缩包只包含基础插件的 Lua 文件：

`trm_weapon_base_scope_fix/lua`

M4 和 VEL/MP7 武器包只是用来参考插槽名称、分类、骨骼和附件行为，没有包含在这个压缩包里。

主要修改文件是：

`lua/weapons/trm_gun_base/modules/client/cl_attachments.lua`

这个文件注册了自定义附件菜单：

`vgui.Register("TRM_AttachMenu", PANEL, "DFrame")`

菜单通过以下控制台命令打开：

`+trmbase_customize`

附件菜单是一个全屏 Derma 界面，但整体透明度降低了，所以玩家仍然可以看到周围环境。武器模型放在一个独立的半透明预览框里。

武器预览使用 `DModelPanel`。玩家可以用鼠标拖动旋转武器，也可以用滚轮缩放武器。

之前的指针线系统已经移除，因为 viewmodel 和 worldmodel 的附件点经常不能和菜单里实际看到的模型位置对齐。现在所有附件插槽都会显示在武器下方的底部栏里，类似现代武器改装界面。

底部每一个插槽按钮都对应：

`SWEP.Attachments`

点击插槽后会切换当前插槽，然后调用：

`RefreshAttList()`

右侧附件列表只会显示该插槽分类可以使用的附件。过滤逻辑在 `GetAttachmentsForSlot(slot)` 里，它会比较插槽分类和 `BASE_TRM_ATTS` 里的附件分类。

当玩家点击某个附件时，`AddAttButton()` 会先在客户端本地更新选择状态，然后调用：

`weapon:SendAttachmentToServer(slotKey, id)`

服务器会通过 TRM Base 原本的网络逻辑应用附件。客户端也会刷新预览模型和附件列表。

预览模型会使用当前附件数据，包括附件模型、bonemerge、骨骼、位置、角度和 bodygroup。选择附件后，`RefreshPreview()` 会删除旧的客户端预览附件模型，并重新创建新的预览附件模型。

左侧统计面板会读取武器基础数据，并模拟附件对属性的修改。它显示伤害、弹匣容量、射速、散布、瞄准时间和后坐力。统计数据由 `BuildStats()` 生成。

这个压缩包包含基础插件所有 Lua 文件，不包含模型、材质、声音或武器包，所以文件体积很小，方便查看和备份。
