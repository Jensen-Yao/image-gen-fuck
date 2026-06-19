(() => {
  if (window.__imageGenCliSettingsInstalled) return;
  window.__imageGenCliSettingsInstalled = true;

  const STYLE_ID = "imagegen-cli-settings-style";
  const BUTTON_ID = "imagegen-cli-settings-button";
  const OVERLAY_ID = "imagegen-cli-settings-overlay";
  const DEFAULT_BASE_URL = "https://code.codingplay.top/v1";
  const DEFAULT_ENV = "OPENAI_API_KEY";
  const HELPER_PATH = "$env:USERPROFILE\\.codex\\skills\\image-gen-fuck\\scripts\\configure_imagegen_cli.ps1";

  async function bridge(path, payload = {}) {
    const fn = window.__codexSessionDeleteBridge;
    if (typeof fn === "function") return fn(path, payload);
    const base = window.__CODEX_SESSION_DELETE_HELPER__ || "http://127.0.0.1:57321";
    const response = await fetch(`${base}${path}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    return response.json();
  }

  function installStyle() {
    if (document.getElementById(STYLE_ID)) return;
    const style = document.createElement("style");
    style.id = STYLE_ID;
    style.textContent = `
      #${BUTTON_ID} {
        position: fixed;
        right: 18px;
        bottom: 18px;
        transform: none;
        z-index: 2147483647;
        pointer-events: auto;
        border: 1px solid rgba(148, 163, 184, .45);
        border-radius: 999px;
        background: rgba(24, 24, 27, .94);
        color: #f8fafc;
        font: 13px/1.2 system-ui, sans-serif;
        min-width: 104px;
        min-height: 44px;
        padding: 10px 16px;
        cursor: pointer;
        box-shadow: 0 14px 34px rgba(0,0,0,.32);
        user-select: none;
        touch-action: manipulation;
      }
      #${BUTTON_ID}:hover { background: rgba(39, 39, 42, .98); }
      #${OVERLAY_ID} {
        position: fixed;
        inset: 0;
        z-index: 2147483000;
        display: flex;
        align-items: center;
        justify-content: center;
        background: rgba(0,0,0,.45);
      }
      .igcli-panel {
        width: min(560px, calc(100vw - 32px));
        border: 1px solid rgba(148, 163, 184, .35);
        border-radius: 10px;
        background: #18181b;
        color: #f8fafc;
        box-shadow: 0 24px 80px rgba(0,0,0,.4);
        font: 13px/1.45 system-ui, sans-serif;
      }
      .igcli-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 12px;
        padding: 14px 16px;
        border-bottom: 1px solid rgba(148, 163, 184, .22);
      }
      .igcli-title { font-size: 15px; font-weight: 650; }
      .igcli-body { padding: 16px; display: grid; gap: 12px; }
      .igcli-row { display: grid; gap: 6px; }
      .igcli-row label { color: #cbd5e1; font-size: 12px; }
      .igcli-row input {
        width: 100%;
        box-sizing: border-box;
        border: 1px solid rgba(148, 163, 184, .28);
        border-radius: 7px;
        background: #27272a;
        color: #f8fafc;
        padding: 8px 10px;
        font: 13px/1.35 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
      }
      .igcli-check { display: flex; align-items: center; gap: 8px; color: #cbd5e1; }
      .igcli-actions { display: flex; flex-wrap: wrap; gap: 8px; padding: 0 16px 16px; }
      .igcli-actions button, .igcli-close {
        border: 1px solid rgba(148, 163, 184, .32);
        border-radius: 7px;
        background: #3f3f46;
        color: #f8fafc;
        padding: 7px 10px;
        font: 13px/1.2 system-ui, sans-serif;
        cursor: pointer;
      }
      .igcli-actions button:hover, .igcli-close:hover { background: #52525b; }
      .igcli-primary { background: #0f766e !important; border-color: #14b8a6 !important; }
      .igcli-danger { background: #7f1d1d !important; border-color: #ef4444 !important; }
      .igcli-note {
        color: #94a3b8;
        font-size: 12px;
        padding: 0 16px 14px;
      }
      .igcli-status {
        min-height: 18px;
        color: #a7f3d0;
        padding: 0 16px 14px;
        font-size: 12px;
        white-space: pre-wrap;
      }
      .igcli-command {
        margin: 0 16px 14px;
        padding: 10px;
        border-radius: 7px;
        background: #09090b;
        color: #e2e8f0;
        font: 12px/1.45 ui-monospace, SFMono-Regular, Menlo, Consolas, monospace;
        white-space: pre-wrap;
        overflow-wrap: anywhere;
      }
    `;
    document.documentElement.appendChild(style);
  }

  function commandText(baseUrl) {
    const escapedBase = String(baseUrl || DEFAULT_BASE_URL).replace(/"/g, '\\"');
    return `powershell -NoProfile -ExecutionPolicy Bypass -File "${HELPER_PATH}" -BaseUrl "${escapedBase}"`;
  }

  function showStatus(root, text, isError = false) {
    const node = root.querySelector(".igcli-status");
    if (!node) return;
    node.style.color = isError ? "#fecaca" : "#a7f3d0";
    node.textContent = text || "";
  }

  async function copyText(text) {
    try {
      await navigator.clipboard.writeText(text);
      return true;
    } catch (_) {
      const area = document.createElement("textarea");
      area.value = text;
      area.style.position = "fixed";
      area.style.left = "-9999px";
      document.body.appendChild(area);
      area.select();
      const ok = document.execCommand("copy");
      area.remove();
      return ok;
    }
  }

  async function openPanel() {
    document.getElementById(OVERLAY_ID)?.remove();
    const overlay = document.createElement("div");
    overlay.id = OVERLAY_ID;
    overlay.innerHTML = `
      <section class="igcli-panel" role="dialog" aria-modal="true" aria-label="ImageGen \u7ed8\u56fe CLI \u8bbe\u7f6e">
        <div class="igcli-header">
          <div class="igcli-title">ImageGen \u7ed8\u56fe\u8bbe\u7f6e</div>
          <button class="igcli-close" type="button">\u5173\u95ed</button>
        </div>
        <div class="igcli-body">
          <label class="igcli-check"><input data-field="enabled" type="checkbox"> \u542f\u7528 CLI \u7ed8\u56fe API \u8bbe\u7f6e</label>
          <div class="igcli-row">
            <label>\u63a5\u53e3\u5730\u5740 (Base URL)</label>
            <input data-field="baseUrl" value="${DEFAULT_BASE_URL}">
          </div>
          <div class="igcli-row">
            <label>API Key \u73af\u5883\u53d8\u91cf\u540d</label>
            <input data-field="apiKeyEnv" value="${DEFAULT_ENV}">
          </div>
          <div class="igcli-row">
            <label>API Key</label>
            <input data-field="apiKey" type="password" autocomplete="off" placeholder="\u7559\u7a7a\u5219\u4fdd\u7559\u5df2\u4fdd\u5b58\u7684 key">
          </div>
        </div>
        <div class="igcli-actions">
          <button class="igcli-primary" data-action="save" type="button">\u4fdd\u5b58\u5230 Codex++</button>
          <button data-action="copy-command" type="button">\u590d\u5236\u672c\u5730\u914d\u7f6e\u547d\u4ee4</button>
          <button class="igcli-danger" data-action="disable" type="button">\u7981\u7528</button>
        </div>
        <div class="igcli-note">\u4fdd\u5b58\u4f1a\u5199\u5165 Codex++ settings.json\u3002\u5982\u9700\u540c\u6b65\u5907\u7528 key \u6587\u4ef6\uff0c\u8bf7\u5728 PowerShell \u8fd0\u884c\u672c\u5730\u914d\u7f6e\u547d\u4ee4\u3002</div>
        <pre class="igcli-command"></pre>
        <div class="igcli-status"></div>
      </section>
    `;
    document.body.appendChild(overlay);

    const panel = overlay.querySelector(".igcli-panel");
    const enabled = overlay.querySelector('[data-field="enabled"]');
    const baseUrl = overlay.querySelector('[data-field="baseUrl"]');
    const apiKeyEnv = overlay.querySelector('[data-field="apiKeyEnv"]');
    const apiKey = overlay.querySelector('[data-field="apiKey"]');
    const command = overlay.querySelector(".igcli-command");

    const refreshCommand = () => {
      command.textContent = commandText(baseUrl.value.trim() || DEFAULT_BASE_URL);
    };
    baseUrl.addEventListener("input", refreshCommand);
    refreshCommand();

    overlay.querySelector(".igcli-close").addEventListener("click", () => overlay.remove());
    overlay.addEventListener("click", (event) => {
      if (event.target === overlay) overlay.remove();
    });

    try {
      const settings = await bridge("/settings/get", {});
      enabled.checked = !!settings.cliWrapperEnabled;
      baseUrl.value = settings.cliWrapperBaseUrl || DEFAULT_BASE_URL;
      apiKeyEnv.value = settings.cliWrapperApiKeyEnv || DEFAULT_ENV;
      apiKey.placeholder = settings.cliWrapperApiKey ? "\u5df2\u4fdd\u5b58\uff1b\u7559\u7a7a\u5219\u4fdd\u7559\u73b0\u6709 key" : "\u8bf7\u8f93\u5165\u7ed8\u56fe API key";
      refreshCommand();
      showStatus(panel, "\u5df2\u8bfb\u53d6 Codex++ \u8bbe\u7f6e\u3002");
    } catch (error) {
      showStatus(panel, `\u8bfb\u53d6\u5931\u8d25\uff1a${error?.message || error}`, true);
    }

    overlay.querySelector('[data-action="save"]').addEventListener("click", async () => {
      try {
        const payload = {
          cliWrapperEnabled: enabled.checked,
          cliWrapperBaseUrl: baseUrl.value.trim() || DEFAULT_BASE_URL,
          cliWrapperApiKeyEnv: apiKeyEnv.value.trim() || DEFAULT_ENV,
        };
        if (apiKey.value.trim()) payload.cliWrapperApiKey = apiKey.value.trim();
        const result = await bridge("/settings/set", payload);
        if (result?.status === "failed") throw new Error(result.message || "\u4fdd\u5b58\u5931\u8d25");
        apiKey.value = "";
        apiKey.placeholder = payload.cliWrapperApiKey ? "\u5df2\u4fdd\u5b58\uff1b\u7559\u7a7a\u5219\u4fdd\u7559\u73b0\u6709 key" : apiKey.placeholder;
        showStatus(panel, "\u5df2\u4fdd\u5b58\u5230 Codex++ settings.json\u3002");
      } catch (error) {
        showStatus(panel, `\u4fdd\u5b58\u5931\u8d25\uff1a${error?.message || error}`, true);
      }
    });

    overlay.querySelector('[data-action="disable"]').addEventListener("click", async () => {
      try {
        const result = await bridge("/settings/set", {
          cliWrapperEnabled: false,
          cliWrapperBaseUrl: "",
          cliWrapperApiKeyEnv: DEFAULT_ENV,
        });
        if (result?.status === "failed") throw new Error(result.message || "\u7981\u7528\u5931\u8d25");
        enabled.checked = false;
        showStatus(panel, "\u5df2\u7981\u7528 CLI \u7ed8\u56fe API \u8bbe\u7f6e\u3002");
      } catch (error) {
        showStatus(panel, `\u7981\u7528\u5931\u8d25\uff1a${error?.message || error}`, true);
      }
    });

    overlay.querySelector('[data-action="copy-command"]').addEventListener("click", async () => {
      const text = commandText(baseUrl.value.trim() || DEFAULT_BASE_URL);
      const ok = await copyText(text);
      showStatus(panel, ok ? "\u547d\u4ee4\u5df2\u590d\u5236\u3002\u8bf7\u5728 PowerShell \u8fd0\u884c\u5b83\uff0c\u4ee5\u540c\u6b65\u5907\u7528 key \u6587\u4ef6\u3002" : "\u590d\u5236\u5931\u8d25\uff1b\u8bf7\u624b\u52a8\u590d\u5236\u547d\u4ee4\u3002", !ok);
    });
  }

  function installButton() {
    if (document.getElementById(BUTTON_ID)) return;
    const button = document.createElement("button");
    button.id = BUTTON_ID;
    button.type = "button";
    button.textContent = "\u7ed8\u56fe\u8bbe\u7f6e";
    button.title = "ImageGen \u7ed8\u56fe CLI \u8bbe\u7f6e";
    const activate = (event) => {
      event.preventDefault();
      event.stopPropagation();
      event.stopImmediatePropagation?.();
      openPanel();
    };
    button.addEventListener("pointerdown", activate, true);
    button.addEventListener("click", activate, true);
    (document.body || document.documentElement).appendChild(button);
  }

  function boot() {
    installStyle();
    installButton();
  }

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", boot, { once: true });
  } else {
    boot();
  }
})();
