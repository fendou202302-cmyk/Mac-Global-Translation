import AppKit
import Carbon
import Security

private let appName = "Input Translator"
private let keychainService = "InputTranslatorMac"
private let providerSetting = "provider"
private let legacyKeychainAccount = "DeepSeekAPIKey"

private let keyCodeA: CGKeyCode = 0
private let keyCodeC: CGKeyCode = 8
private let keyCodeV: CGKeyCode = 9
private let keyCodeT: UInt32 = UInt32(kVK_ANSI_T)
private let shortcutKeyCodeSetting = "shortcutKeyCode"
private let shortcutCommandSetting = "shortcutCommand"
private let shortcutControlSetting = "shortcutControl"
private let shortcutOptionSetting = "shortcutOption"
private let shortcutShiftSetting = "shortcutShift"

private let supportedShortcutKeys: [(name: String, keyCode: UInt32)] = [
    ("A", UInt32(kVK_ANSI_A)),
    ("B", UInt32(kVK_ANSI_B)),
    ("C", UInt32(kVK_ANSI_C)),
    ("D", UInt32(kVK_ANSI_D)),
    ("E", UInt32(kVK_ANSI_E)),
    ("F", UInt32(kVK_ANSI_F)),
    ("G", UInt32(kVK_ANSI_G)),
    ("H", UInt32(kVK_ANSI_H)),
    ("I", UInt32(kVK_ANSI_I)),
    ("J", UInt32(kVK_ANSI_J)),
    ("K", UInt32(kVK_ANSI_K)),
    ("L", UInt32(kVK_ANSI_L)),
    ("M", UInt32(kVK_ANSI_M)),
    ("N", UInt32(kVK_ANSI_N)),
    ("O", UInt32(kVK_ANSI_O)),
    ("P", UInt32(kVK_ANSI_P)),
    ("Q", UInt32(kVK_ANSI_Q)),
    ("R", UInt32(kVK_ANSI_R)),
    ("S", UInt32(kVK_ANSI_S)),
    ("T", UInt32(kVK_ANSI_T)),
    ("U", UInt32(kVK_ANSI_U)),
    ("V", UInt32(kVK_ANSI_V)),
    ("W", UInt32(kVK_ANSI_W)),
    ("X", UInt32(kVK_ANSI_X)),
    ("Y", UInt32(kVK_ANSI_Y)),
    ("Z", UInt32(kVK_ANSI_Z))
]

private enum ProviderKind {
    case openAICompatible(endpoint: String)
    case anthropic
    case gemini
}

private struct AIProvider {
    let id: String
    let name: String
    let apiKeyLabel: String
    let models: [String]
    let kind: ProviderKind
}

private let aiProviders: [AIProvider] = [
    AIProvider(
        id: "deepseek",
        name: "DeepSeek",
        apiKeyLabel: "DeepSeek API Key",
        models: ["deepseek-v4-flash", "deepseek-v4-pro", "deepseek-chat"],
        kind: .openAICompatible(endpoint: "https://api.deepseek.com/chat/completions")
    ),
    AIProvider(
        id: "openai",
        name: "OpenAI",
        apiKeyLabel: "OpenAI API Key",
        models: ["gpt-4.1-mini", "gpt-4.1", "gpt-4o-mini", "gpt-4o"],
        kind: .openAICompatible(endpoint: "https://api.openai.com/v1/chat/completions")
    ),
    AIProvider(
        id: "anthropic",
        name: "Anthropic Claude",
        apiKeyLabel: "Anthropic API Key",
        models: ["claude-3-5-haiku-latest", "claude-3-7-sonnet-latest", "claude-sonnet-4-20250514"],
        kind: .anthropic
    ),
    AIProvider(
        id: "gemini",
        name: "Google Gemini",
        apiKeyLabel: "Gemini API Key",
        models: ["gemini-2.5-flash", "gemini-2.5-pro", "gemini-2.0-flash"],
        kind: .gemini
    ),
    AIProvider(
        id: "qwen",
        name: "通义千问 Qwen",
        apiKeyLabel: "DashScope API Key",
        models: ["qwen-turbo", "qwen-plus", "qwen-max", "qwen-long"],
        kind: .openAICompatible(endpoint: "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions")
    ),
    AIProvider(
        id: "moonshot",
        name: "Kimi / Moonshot",
        apiKeyLabel: "Moonshot API Key",
        models: ["moonshot-v1-8k", "moonshot-v1-32k", "moonshot-v1-128k"],
        kind: .openAICompatible(endpoint: "https://api.moonshot.cn/v1/chat/completions")
    ),
    AIProvider(
        id: "openrouter",
        name: "OpenRouter",
        apiKeyLabel: "OpenRouter API Key",
        models: ["openai/gpt-4o-mini", "anthropic/claude-3.5-haiku", "google/gemini-2.0-flash-001"],
        kind: .openAICompatible(endpoint: "https://openrouter.ai/api/v1/chat/completions")
    ),
    AIProvider(
        id: "siliconflow",
        name: "硅基流动 SiliconFlow",
        apiKeyLabel: "SiliconFlow API Key",
        models: ["Qwen/Qwen2.5-72B-Instruct", "deepseek-ai/DeepSeek-V3", "THUDM/glm-4-9b-chat"],
        kind: .openAICompatible(endpoint: "https://api.siliconflow.cn/v1/chat/completions")
    )
]

private let supportedLanguages: [(name: String, value: String)] = [
    ("英文 English", "English"),
    ("简体中文 Simplified Chinese", "Simplified Chinese"),
    ("繁体中文 Traditional Chinese", "Traditional Chinese"),
    ("日文 Japanese", "Japanese"),
    ("韩文 Korean", "Korean"),
    ("法文 French", "French"),
    ("德文 German", "German"),
    ("西班牙文 Spanish", "Spanish"),
    ("葡萄牙文 Portuguese", "Portuguese"),
    ("意大利文 Italian", "Italian"),
    ("俄文 Russian", "Russian"),
    ("阿拉伯文 Arabic", "Arabic"),
    ("印地文 Hindi", "Hindi"),
    ("印尼文 Indonesian", "Indonesian"),
    ("泰文 Thai", "Thai"),
    ("越南文 Vietnamese", "Vietnamese"),
    ("土耳其文 Turkish", "Turkish"),
    ("荷兰文 Dutch", "Dutch"),
    ("波兰文 Polish", "Polish"),
    ("瑞典文 Swedish", "Swedish")
]

private func fourCharCode(_ string: String) -> OSType {
    var result: OSType = 0
    for scalar in string.utf8 {
        result = (result << 8) + OSType(scalar)
    }
    return result
}

private func boolSetting(_ key: String, defaultValue: Bool) -> Bool {
    let defaults = UserDefaults.standard
    guard defaults.object(forKey: key) != nil else { return defaultValue }
    return defaults.bool(forKey: key)
}

private func shortcutKeyCodeSettingValue() -> UInt32 {
    let defaults = UserDefaults.standard
    guard defaults.object(forKey: shortcutKeyCodeSetting) != nil else { return keyCodeT }
    return UInt32(defaults.integer(forKey: shortcutKeyCodeSetting))
}

private func shortcutCarbonModifiers() -> UInt32 {
    var modifiers: UInt32 = 0
    if boolSetting(shortcutCommandSetting, defaultValue: false) { modifiers |= UInt32(cmdKey) }
    if boolSetting(shortcutControlSetting, defaultValue: true) { modifiers |= UInt32(controlKey) }
    if boolSetting(shortcutOptionSetting, defaultValue: true) { modifiers |= UInt32(optionKey) }
    if boolSetting(shortcutShiftSetting, defaultValue: false) { modifiers |= UInt32(shiftKey) }
    return modifiers
}

private func shortcutDisplayName() -> String {
    var parts: [String] = []
    if boolSetting(shortcutCommandSetting, defaultValue: false) { parts.append("Command") }
    if boolSetting(shortcutControlSetting, defaultValue: true) { parts.append("Control") }
    if boolSetting(shortcutOptionSetting, defaultValue: true) { parts.append("Option") }
    if boolSetting(shortcutShiftSetting, defaultValue: false) { parts.append("Shift") }

    let keyCode = shortcutKeyCodeSettingValue()
    let keyName = supportedShortcutKeys.first(where: { $0.keyCode == keyCode })?.name ?? "T"
    parts.append(keyName)
    return parts.joined(separator: " + ")
}

private final class KeychainStore {
    static func readAPIKey(providerID: String) -> String {
        let primaryKey = readAPIKey(account: keychainAccount(providerID: providerID))
        if !primaryKey.isEmpty || providerID != "deepseek" { return primaryKey }
        return readAPIKey(account: legacyKeychainAccount)
    }

    static func saveAPIKey(_ apiKey: String, providerID: String) {
        saveAPIKey(apiKey, account: keychainAccount(providerID: providerID))
    }

    private static func keychainAccount(providerID: String) -> String {
        "APIKey.\(providerID)"
    }

    private static func readAPIKey(account: String) -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess, let data = item as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    private static func saveAPIKey(_ apiKey: String, account: String) {
        let data = Data(apiKey.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: account
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            var newItem = query
            newItem[kSecValueData as String] = data
            SecItemAdd(newItem as CFDictionary, nil)
        }
    }
}

private struct DeepSeekResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let content: String
        }

        let message: Message
    }

    let choices: [Choice]
}

private struct DeepSeekErrorResponse: Decodable {
    struct APIError: Decodable {
        let message: String
    }

    let error: APIError?
}

private final class PasteableSecureTextField: NSSecureTextField {
    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command), event.charactersIgnoringModifiers?.lowercased() == "v" {
            currentEditor()?.paste(nil)
            return true
        }

        return super.performKeyEquivalent(with: event)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        setupPasteMenu()
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupPasteMenu()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPasteMenu()
    }

    private func setupPasteMenu() {
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
        self.menu = menu
    }
}

private final class SettingsWindowController: NSWindowController {
    private let providerPopup = NSPopUpButton()
    private let apiKeyLabel = NSTextField(labelWithString: "API Key")
    private let apiKeyField = PasteableSecureTextField()
    private let targetLanguagePopup = NSPopUpButton()
    private let modelPopup = NSPopUpButton()
    private let commandCheckbox = NSButton(checkboxWithTitle: "Command", target: nil, action: nil)
    private let controlCheckbox = NSButton(checkboxWithTitle: "Control", target: nil, action: nil)
    private let optionCheckbox = NSButton(checkboxWithTitle: "Option", target: nil, action: nil)
    private let shiftCheckbox = NSButton(checkboxWithTitle: "Shift", target: nil, action: nil)
    private let shortcutKeyPopup = NSPopUpButton()
    private let statusLabel = NSTextField(labelWithString: "")

    init() {
        let contentView = NSView(frame: NSRect(x: 0, y: 0, width: 460, height: 370))
        let window = NSWindow(
            contentRect: contentView.frame,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(appName) Settings"
        window.center()
        window.contentView = contentView
        super.init(window: window)

        buildUI(in: contentView)
        loadSettings()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func buildUI(in view: NSView) {
        let titleLabel = NSTextField(labelWithString: "Input Translator")
        titleLabel.font = .boldSystemFont(ofSize: 18)
        titleLabel.frame = NSRect(x: 24, y: 324, width: 260, height: 24)
        view.addSubview(titleLabel)

        addLabel("服务商", x: 24, y: 286, view: view)
        providerPopup.addItems(withTitles: aiProviders.map { $0.name })
        providerPopup.target = self
        providerPopup.action = #selector(providerChanged)
        providerPopup.frame = NSRect(x: 154, y: 280, width: 264, height: 30)
        view.addSubview(providerPopup)

        apiKeyLabel.frame = NSRect(x: 24, y: 242, width: 122, height: 20)
        view.addSubview(apiKeyLabel)

        apiKeyField.placeholderString = "sk-..."
        apiKeyField.frame = NSRect(x: 154, y: 236, width: 178, height: 28)
        view.addSubview(apiKeyField)

        let pasteButton = NSButton(title: "粘贴", target: self, action: #selector(pasteAPIKey))
        pasteButton.bezelStyle = .rounded
        pasteButton.frame = NSRect(x: 344, y: 235, width: 74, height: 30)
        view.addSubview(pasteButton)

        addLabel("目标语言", x: 24, y: 198, view: view)
        targetLanguagePopup.addItems(withTitles: supportedLanguages.map { $0.name })
        targetLanguagePopup.frame = NSRect(x: 154, y: 192, width: 264, height: 30)
        view.addSubview(targetLanguagePopup)

        addLabel("模型", x: 24, y: 154, view: view)
        modelPopup.frame = NSRect(x: 154, y: 148, width: 264, height: 30)
        view.addSubview(modelPopup)

        addLabel("快捷键", x: 24, y: 110, view: view)
        commandCheckbox.frame = NSRect(x: 154, y: 107, width: 100, height: 24)
        controlCheckbox.frame = NSRect(x: 264, y: 107, width: 100, height: 24)
        optionCheckbox.frame = NSRect(x: 154, y: 78, width: 100, height: 24)
        shiftCheckbox.frame = NSRect(x: 264, y: 78, width: 100, height: 24)
        view.addSubview(commandCheckbox)
        view.addSubview(controlCheckbox)
        view.addSubview(optionCheckbox)
        view.addSubview(shiftCheckbox)

        shortcutKeyPopup.addItems(withTitles: supportedShortcutKeys.map { $0.name })
        shortcutKeyPopup.frame = NSRect(x: 154, y: 46, width: 86, height: 30)
        view.addSubview(shortcutKeyPopup)

        let saveButton = NSButton(title: "保存", target: self, action: #selector(saveSettings))
        saveButton.bezelStyle = .rounded
        saveButton.frame = NSRect(x: 154, y: 12, width: 86, height: 32)
        view.addSubview(saveButton)

        statusLabel.textColor = .secondaryLabelColor
        statusLabel.frame = NSRect(x: 254, y: 17, width: 180, height: 20)
        view.addSubview(statusLabel)
    }

    private func addLabel(_ text: String, x: CGFloat, y: CGFloat, view: NSView) {
        let label = NSTextField(labelWithString: text)
        label.frame = NSRect(x: x, y: y, width: 110, height: 20)
        view.addSubview(label)
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard
        let provider = selectedProviderFromDefaults()
        providerPopup.selectItem(withTitle: provider.name)
        loadProviderFields(provider: provider)

        let targetLanguage = defaults.string(forKey: "targetLanguage") ?? "English"
        let targetLanguageName = supportedLanguages.first(where: { $0.value == targetLanguage })?.name ?? supportedLanguages[0].name
        targetLanguagePopup.selectItem(withTitle: targetLanguageName)

        commandCheckbox.state = boolSetting(shortcutCommandSetting, defaultValue: false) ? .on : .off
        controlCheckbox.state = boolSetting(shortcutControlSetting, defaultValue: true) ? .on : .off
        optionCheckbox.state = boolSetting(shortcutOptionSetting, defaultValue: true) ? .on : .off
        shiftCheckbox.state = boolSetting(shortcutShiftSetting, defaultValue: false) ? .on : .off

        let shortcutKeyCode = shortcutKeyCodeSettingValue()
        if let keyName = supportedShortcutKeys.first(where: { $0.keyCode == shortcutKeyCode })?.name {
            shortcutKeyPopup.selectItem(withTitle: keyName)
        } else {
            shortcutKeyPopup.selectItem(withTitle: "T")
        }
    }

    private func selectedProviderFromDefaults() -> AIProvider {
        let providerID = UserDefaults.standard.string(forKey: providerSetting) ?? "deepseek"
        return aiProviders.first(where: { $0.id == providerID }) ?? aiProviders[0]
    }

    private func selectedProvider() -> AIProvider {
        let providerName = providerPopup.titleOfSelectedItem ?? aiProviders[0].name
        return aiProviders.first(where: { $0.name == providerName }) ?? aiProviders[0]
    }

    private func loadProviderFields(provider: AIProvider) {
        apiKeyLabel.stringValue = provider.apiKeyLabel
        apiKeyField.placeholderString = provider.id == "gemini" ? "AIza..." : "sk-..."
        apiKeyField.stringValue = KeychainStore.readAPIKey(providerID: provider.id)

        modelPopup.removeAllItems()
        modelPopup.addItems(withTitles: provider.models)
        let savedModel = UserDefaults.standard.string(forKey: modelSetting(providerID: provider.id)) ?? provider.models[0]
        modelPopup.selectItem(withTitle: savedModel)
    }

    @objc private func providerChanged() {
        loadProviderFields(provider: selectedProvider())
        statusLabel.stringValue = ""
    }

    @objc private func saveSettings() {
        let defaults = UserDefaults.standard
        let hasModifier = commandCheckbox.state == .on || controlCheckbox.state == .on || optionCheckbox.state == .on || shiftCheckbox.state == .on
        guard hasModifier else {
            statusLabel.stringValue = "至少选一个修饰键"
            return
        }

        let provider = selectedProvider()
        KeychainStore.saveAPIKey(apiKeyField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines), providerID: provider.id)
        defaults.set(provider.id, forKey: providerSetting)

        let languageName = targetLanguagePopup.titleOfSelectedItem ?? supportedLanguages[0].name
        let languageValue = supportedLanguages.first(where: { $0.name == languageName })?.value ?? "English"
        defaults.set(languageValue, forKey: "targetLanguage")

        defaults.set(modelPopup.titleOfSelectedItem ?? provider.models[0], forKey: modelSetting(providerID: provider.id))
        defaults.set(commandCheckbox.state == .on, forKey: shortcutCommandSetting)
        defaults.set(controlCheckbox.state == .on, forKey: shortcutControlSetting)
        defaults.set(optionCheckbox.state == .on, forKey: shortcutOptionSetting)
        defaults.set(shiftCheckbox.state == .on, forKey: shortcutShiftSetting)

        let keyName = shortcutKeyPopup.titleOfSelectedItem ?? "T"
        let keyCode = supportedShortcutKeys.first(where: { $0.name == keyName })?.keyCode ?? keyCodeT
        defaults.set(Int(keyCode), forKey: shortcutKeyCodeSetting)

        TranslatorApp.shared?.reloadGlobalHotKey()
        statusLabel.stringValue = "已保存：\(shortcutDisplayName())"
    }

    @objc private func pasteAPIKey() {
        if let text = NSPasteboard.general.string(forType: .string) {
            apiKeyField.stringValue = text.trimmingCharacters(in: .whitespacesAndNewlines)
            statusLabel.stringValue = "已粘贴"
        }
    }
}

private func modelSetting(providerID: String) -> String {
    "model.\(providerID)"
}

private final class TranslatorApp: NSObject, NSApplicationDelegate {
    static var shared: TranslatorApp?

    private var statusItem: NSStatusItem!
    private var hotKeyRef: EventHotKeyRef?
    private var hotKeyHandlerInstalled = false
    private var settingsWindowController: SettingsWindowController?
    private var savedClipboardText: String?

    func applicationDidFinishLaunching(_ notification: Notification) {
        TranslatorApp.shared = self
        NSApp.setActivationPolicy(.accessory)
        setupMenu()
        registerGlobalHotKey()
    }

    private func setupMenu() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "译"
        statusItem.button?.toolTip = "Input Translator"

        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "翻译当前输入", action: #selector(translateCurrentInput), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "设置...", action: #selector(openSettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "打开辅助功能设置", action: #selector(openAccessibilitySettings), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "退出", action: #selector(quit), keyEquivalent: "q"))
        statusItem.menu = menu
    }

    private func registerGlobalHotKey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }

        let hotKeyID = EventHotKeyID(signature: fourCharCode("ITRA"), id: 1)
        RegisterEventHotKey(shortcutKeyCodeSettingValue(), shortcutCarbonModifiers(), hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)

        if !hotKeyHandlerInstalled {
            var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
            InstallEventHandler(GetApplicationEventTarget(), { _, _, _ in
                DispatchQueue.main.async {
                    TranslatorApp.shared?.translateCurrentInput()
                }
                return noErr
            }, 1, &eventType, nil, nil)
            hotKeyHandlerInstalled = true
        }
    }

    func reloadGlobalHotKey() {
        registerGlobalHotKey()
    }

    @objc private func openSettings() {
        if settingsWindowController == nil {
            settingsWindowController = SettingsWindowController()
        }
        settingsWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    @objc private func translateCurrentInput() {
        guard hasAccessibilityPermission() else {
            showAccessibilityHelp()
            return
        }

        let provider = currentProvider()
        let apiKey = KeychainStore.readAPIKey(providerID: provider.id).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            openSettings()
            showNotification("请先填写 \(provider.apiKeyLabel)", "保存后再按 \(shortcutDisplayName())。")
            return
        }

        let pasteboard = NSPasteboard.general
        savedClipboardText = pasteboard.string(forType: .string)
        pasteboard.clearContents()

        postKey(keyCodeA, flags: .maskCommand)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.postKey(keyCodeC, flags: .maskCommand)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            let text = pasteboard.string(forType: .string) ?? ""
            guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                self.restoreClipboard()
                self.showNotification("没有读到可翻译文本", "请先把光标放在输入框里，或选中一段文字。")
                return
            }

            self.setBusy(true)
            self.translate(text: text, provider: provider, apiKey: apiKey) { result in
                DispatchQueue.main.async {
                    self.setBusy(false)
                    switch result {
                    case .success(let translatedText):
                        pasteboard.clearContents()
                        pasteboard.setString(translatedText, forType: .string)
                        self.postKey(keyCodeV, flags: .maskCommand)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.restoreClipboard()
                        }
                    case .failure(let error):
                        self.restoreClipboard()
                        self.showNotification("翻译失败", error.localizedDescription)
                    }
                }
            }
        }
    }

    private func currentProvider() -> AIProvider {
        let providerID = UserDefaults.standard.string(forKey: providerSetting) ?? "deepseek"
        return aiProviders.first(where: { $0.id == providerID }) ?? aiProviders[0]
    }

    private func translate(text: String, provider: AIProvider, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        let defaults = UserDefaults.standard
        let targetLanguage = defaults.string(forKey: "targetLanguage") ?? "English"
        let model = defaults.string(forKey: modelSetting(providerID: provider.id)) ?? provider.models[0]

        switch provider.kind {
        case .openAICompatible(let endpoint):
            translateWithOpenAICompatible(text: text, targetLanguage: targetLanguage, provider: provider, endpoint: endpoint, model: model, apiKey: apiKey, completion: completion)
        case .anthropic:
            translateWithAnthropic(text: text, targetLanguage: targetLanguage, model: model, apiKey: apiKey, completion: completion)
        case .gemini:
            translateWithGemini(text: text, targetLanguage: targetLanguage, model: model, apiKey: apiKey, completion: completion)
        }
    }

    private func translateWithOpenAICompatible(text: String, targetLanguage: String, provider: AIProvider, endpoint: String, model: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        if provider.id == "openrouter" {
            request.setValue("Input Translator", forHTTPHeaderField: "X-Title")
        }
        request.timeoutInterval = 45

        let body: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "You are a precise translation engine. Only output the translated text. Keep line breaks, punctuation, emojis, URLs, placeholders, and formatting as much as possible. Do not explain."
                ],
                [
                    "role": "user",
                    "content": "Translate the following text into \(targetLanguage):\n\n\(text)"
                ]
            ],
            "temperature": 0.2,
            "stream": false
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        runChatCompletionRequest(request, completion: completion)
    }

    private func translateWithAnthropic(text: String, targetLanguage: String, model: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 45

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "temperature": 0.2,
            "system": "You are a precise translation engine. Only output the translated text. Keep line breaks, punctuation, emojis, URLs, placeholders, and formatting as much as possible. Do not explain.",
            "messages": [
                [
                    "role": "user",
                    "content": "Translate the following text into \(targetLanguage):\n\n\(text)"
                ]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        runJSONRequest(request) { result in
            switch result {
            case .success(let json):
                if let content = json["content"] as? [[String: Any]],
                   let firstText = content.first(where: { $0["type"] as? String == "text" })?["text"] as? String {
                    completion(.success(firstText.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(NSError(domain: appName, code: -2, userInfo: [NSLocalizedDescriptionKey: "Anthropic 没有返回翻译结果"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func translateWithGemini(text: String, targetLanguage: String, model: String, apiKey: String, completion: @escaping (Result<String, Error>) -> Void) {
        var components = URLComponents(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent")!
        components.queryItems = [URLQueryItem(name: "key", value: apiKey)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 45

        let prompt = "You are a precise translation engine. Only output the translated text. Keep line breaks, punctuation, emojis, URLs, placeholders, and formatting as much as possible. Do not explain.\n\nTranslate the following text into \(targetLanguage):\n\n\(text)"
        let body: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.2
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        runJSONRequest(request) { result in
            switch result {
            case .success(let json):
                if let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    completion(.success(text.trimmingCharacters(in: .whitespacesAndNewlines)))
                } else {
                    completion(.failure(NSError(domain: appName, code: -2, userInfo: [NSLocalizedDescriptionKey: "Gemini 没有返回翻译结果"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    private func runChatCompletionRequest(_ request: URLRequest, completion: @escaping (Result<String, Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: appName, code: -1, userInfo: [NSLocalizedDescriptionKey: "DeepSeek 没有返回数据"])))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let apiError = try? JSONDecoder().decode(DeepSeekErrorResponse.self, from: data)
                let message = apiError?.error?.message ?? "DeepSeek 请求失败：\(httpResponse.statusCode)"
                completion(.failure(NSError(domain: appName, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(DeepSeekResponse.self, from: data)
                let translatedText = decoded.choices.first?.message.content.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if translatedText.isEmpty {
                    completion(.failure(NSError(domain: appName, code: -2, userInfo: [NSLocalizedDescriptionKey: "DeepSeek 没有返回翻译结果"])))
                } else {
                    completion(.success(translatedText))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func runJSONRequest(_ request: URLRequest, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = data else {
                completion(.failure(NSError(domain: appName, code: -1, userInfo: [NSLocalizedDescriptionKey: "接口没有返回数据"])))
                return
            }

            if let httpResponse = response as? HTTPURLResponse, !(200...299).contains(httpResponse.statusCode) {
                let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                let errorObject = object?["error"] as? [String: Any]
                let message = errorObject?["message"] as? String ?? "请求失败：\(httpResponse.statusCode)"
                completion(.failure(NSError(domain: appName, code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: message])))
                return
            }

            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                completion(.success(json ?? [:]))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func postKey(_ keyCode: CGKeyCode, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.post(tap: .cghidEventTap)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.post(tap: .cghidEventTap)
    }

    private func hasAccessibilityPermission() -> Bool {
        AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: false] as CFDictionary)
    }

    private func showAccessibilityHelp() {
        let alert = NSAlert()
        alert.messageText = "需要开启辅助功能权限"
        alert.informativeText = "如果你已经打开过权限，请先把列表里的 Input Translator 删除，再把当前这个 App 重新加入。macOS 会按 App 路径和签名识别权限，重新构建后的 App 可能会被当成新应用。"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "打开设置")
        alert.addButton(withTitle: "稍后")

        if alert.runModal() == .alertFirstButtonReturn {
            openAccessibilitySettings()
        }
    }

    @objc private func openAccessibilitySettings() {
        let urls = [
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security"
        ]

        for value in urls {
            if let url = URL(string: value), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    private func restoreClipboard() {
        guard let savedClipboardText = savedClipboardText else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(savedClipboardText, forType: .string)
    }

    private func setBusy(_ busy: Bool) {
        statusItem.button?.title = busy ? "译..." : "译"
    }

    private func showNotification(_ title: String, _ body: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = body
        alert.alertStyle = .informational
        alert.runModal()
    }
}

let app = NSApplication.shared
private let delegate = TranslatorApp()
app.delegate = delegate
app.run()
