# dsh-wechat-zh

给 [`dsh-wechat-plugin`](https://github.com/xcisxc29/dsh-wechat) 的**中文增强补丁**。
在微信里给电脑上的 DeepSeek Harness 派活时，少打几个字、列表干净一点。

> 本项目**只包含补丁和规则文件**，不包含上游源码。
> 上游作者：**xcisxc29**，许可证 MIT。感谢他做出这么好用的插件。

---

## 改了什么

| # | 改动 | 为什么 |
|---|---|---|
| 1 | 新增中文命令 **「菜单」/「菜单 全部」= `/list`** | 手机输入法打 `/` 和 `list` 要切键盘，中文两个字更快 |
| 2 | 会话列表**去掉尾部的短 id** | 一屏能多显示两行，编号 + 标题已经够认 |
| 3 | 附一份**微信回复规范**（`rules/AGENTS.wechat.md`） | 微信一窗只有 10 条，回复太长会被截断 |

`/switch <短id>` 仍然可用，只是不再打印出来。

---

## 安装

### 前置

已经装好上游插件，并且能正常收发微信：

```
DSH 侧栏 → 插件 → 添加插件 → dsh-wechat-plugin
```

装完**重启一次 DSH**，确认「设置 → 微信」能扫码绑定。

### 打补丁

```powershell
git clone https://github.com/baka-king/dsh-wechat-zh
cd dsh-wechat-zh
powershell -ExecutionPolicy Bypass -File .\apply-patch.ps1
```

没有 git 的话，点右上角 **Code → Download ZIP**，解压后在那个文件夹里开 PowerShell，跑同一条命令。

看到 `已打补丁` 后，**重启 DSH**，微信里发「菜单」试试。

### 回滚

```powershell
powershell -ExecutionPolicy Bypass -File .\apply-patch.ps1 -Restore
```

补丁前的原文件会备份成 `router.js.zh.bak`。

---

## 手动应用（不想跑脚本）

打开：

```
%USERPROFILE%\.dsh\profiles\desktop\node_modules\dsh-wechat-plugin\dist\core\lib\router.js
```

**第一处**，找到 `splitCommand` 里的 `const trimmed = text.trim();`，在它后面插入：

```js
    // 中文别名：「菜单」= /list
    if (trimmed === '菜单')
        return { command: '/list', args: '' };
    if (/^菜单[ 　:：]/.test(trimmed))
        return { command: '/list', args: trimmed.slice(2).replace(/^[:\s：]+/, '').trim() };
```

**第二处**，找到会话列表那行 `return \`${String(index + 1)}. ${title}${when}${mark}  ${shortId(session.sessionId)}\`;`，
把末尾的 `  ${shortId(session.sessionId)}` 删掉。

改完重启 DSH。

---

## 升级注意

**上游升级会覆盖 `dist/`，补丁会丢。** 升级后重跑一次 `apply-patch.ps1` 即可。
建议升级前先 `-Restore`，升完再打。

---

## 规则文件怎么用

`rules/AGENTS.wechat.md` 是给 agent 看的回复规范（≤5 行、长内容转文件、别让用户去点电脑上的路径）。
放到微信那个会话的工作区，或者合并进你已有的 `AGENTS.md`。

`rules/微信菜单-模板.md` 是「用编号指代会话」的模板——把里面的示例换成你自己的会话名。

---

## 已知限制

- 只对 `dsh-wechat-plugin@0.47.0` 验证过；上游改了 `router.js` 结构，脚本会报「找不到锚点」而不是乱改
- 中文别名是精确匹配，`菜单 全部` 这种带空格的才走带参数分支
- 上游如果哪天自己加了中文命令，这个补丁就该退休了

---

## 许可

MIT。原始版权归 **dsh-wechat contributors**，补丁与文档部分归本仓库作者。
见 [LICENSE](LICENSE)。

## 免责

非官方补丁，与上游作者无关。用之前先备份，出问题 `-Restore` 就能回去。
