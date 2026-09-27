import Foundation

/// User-facing language for the Mac Sai interface.
///
/// We keep the preference in the shared defaults suite so the main app and the
/// menu-bar helper switch languages together.
public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case system = "system"
    case de = "de"
    case ru = "ru"
    case zhHans = "zh-Hans"
    case en = "en"

    public static let defaultsKey = "appLanguage"
    public static let fallback: AppLanguage = .en

    public var id: String { rawValue }

    public var localeIdentifier: String { resolved.localeIdentifierForResolvedLanguage }

    private var localeIdentifierForResolvedLanguage: String {
        switch self {
        case .system:
            Self.systemPreferred.localeIdentifierForResolvedLanguage
        case .de:
            "de"
        case .ru:
            "ru"
        case .zhHans:
            "zh-Hans"
        case .en:
            "en"
        }
    }

    public var resolved: AppLanguage {
        switch self {
        case .system: Self.systemPreferred
        case .de, .ru, .zhHans, .en: self
        }
    }

    public static var systemPreferred: AppLanguage {
        let preferred = Locale.preferredLanguages.first ?? Locale.current.identifier
        return preferredLanguage(for: preferred)
    }

    static func preferredLanguage(for identifier: String) -> AppLanguage {
        let normalized = identifier.replacingOccurrences(of: "_", with: "-").lowercased()
        switch normalized.split(separator: "-", maxSplits: 1).first {
        case "de": return .de
        case "ru": return .ru
        case "zh": return .zhHans
        default: return .en
        }
    }

    /// Label shown in the language picker. These are intentionally native names
    /// instead of going through `L10n.tr`, so users can always find their
    /// preferred language even if the current UI language is unfamiliar.
    public var pickerLabel: String {
        switch self {
        case .system: L10n.tr("跟随系统", "System", "Системный")
        case .de: "Deutsch"
        case .ru: "Русский"
        case .zhHans: "简体中文"
        case .en: "English"
        }
    }

    public static var current: AppLanguage {
        get {
            if let raw = SharedAppState.defaults.string(forKey: defaultsKey),
               let language = AppLanguage(rawValue: raw) {
                return language
            }
            if let raw = UserDefaults.standard.string(forKey: defaultsKey),
               let language = AppLanguage(rawValue: raw) {
                return language
            }
            return fallback
        }
        set {
            SharedAppState.defaults.set(newValue.rawValue, forKey: defaultsKey)
            UserDefaults.standard.set(newValue.rawValue, forKey: defaultsKey)
        }
    }

    /// Set a product default without changing an existing user choice. Tests and
    /// command-line tools keep the English fallback, while the shipped apps call
    /// this on launch to follow the user's system language by default.
    public static func registerDefault(_ language: AppLanguage) {
        guard SharedAppState.defaults.string(forKey: defaultsKey) == nil,
              UserDefaults.standard.string(forKey: defaultsKey) == nil else { return }
        current = language
    }
}

/// Lightweight runtime localization used by both executables.
///
/// The project is mostly SwiftUI views plus model strings that were originally
/// hard-coded. A full `.strings` migration would require touching almost every
/// call site and packaging resource bundles for the custom app builder. This
/// helper keeps the current no-resource build flow while still allowing instant
/// Chinese/English/Russian/German switching at runtime.
public enum L10n {
    /// Keeps newly added strings usable until a translation is supplied.
    /// Existing localized strings use the three-argument overload below.
    public static func tr(_ zhHans: String, _ english: @autoclosure () -> String) -> String {
        switch AppLanguage.current.resolved {
        case .zhHans: zhHans
        case .system, .en: english()
        case .de: germanFallbacks[zhHans] ?? english()
        case .ru: russianFallbacks[zhHans] ?? english()
        }
    }

    public static func tr(
        _ zhHans: String,
        _ english: @autoclosure () -> String,
        _ russian: @autoclosure () -> String
    ) -> String {
        switch AppLanguage.current.resolved {
        case .system, .en: english()
        case .de: germanFallbacks[zhHans] ?? english()
        case .ru: russian()
        case .zhHans: zhHans
        }
    }

    public static func tr(_ zhHans: String) -> String {
        switch AppLanguage.current.resolved {
        case .system, .en:
            englishFallbacks[zhHans] ?? zhHans
        case .de:
            germanFallbacks[zhHans] ?? englishFallbacks[zhHans] ?? zhHans
        case .ru:
            russianFallbacks[zhHans] ?? englishFallbacks[zhHans] ?? zhHans
        case .zhHans:
            zhHans
        }
    }

    /// Selects the Russian noun form for a non-negative count.
    /// Examples: 1 файл, 2 файла, 5 файлов, 11 файлов, 21 файл.
    public static func russianPlural(
        _ count: Int,
        one: String,
        few: String,
        many: String
    ) -> String {
        let magnitude = count.magnitude
        let mod10 = magnitude % 10
        let mod100 = magnitude % 100

        if mod10 == 1, mod100 != 11 { return one }
        if (2...4).contains(mod10), !(12...14).contains(mod100) { return few }
        return many
    }

    /// Small fallback table for values that are assembled dynamically or flow
    /// through model properties. Most UI strings use the three-argument overload
    /// so every supported translation lives beside the original expression.
    private static let englishFallbacks: [String: String] = [
        "智能扫描": "Smart Scan",
        "系统垃圾": "System Junk",
        "邮件附件": "Mail Attachments",
        "废纸篓": "Trash Bins",
        "恶意软件清理": "Malware Removal",
        "隐私清理": "Privacy",
        "已保存的 Wi-Fi": "Saved Wi-Fi",
        "应用权限": "App Permissions",
        "权限总览": "Permissions",
        "优化": "Optimization",
        "维护": "Maintenance",
        "卸载器": "Uninstaller",
        "扩展": "Extensions",
        "应用更新": "Updater",
        "空间透视": "Space Lens",
        "大文件与旧文件": "Large & Old Files",
        "重复文件": "Duplicates",
        "文件粉碎": "Shredder",
        "设置": "Settings",
        "清理": "Cleanup",
        "防护": "Protection",
        "性能": "Performance",
        "应用": "Applications",
        "文件": "Files",
        "全部": "All",
        "未使用": "Unused",
        "第三方": "Third-party",
        "快速": "Quick",
        "平衡": "Balanced",
        "深度": "Deep",
        "开启": "enable",
        "关闭": "disable",
        "压缩包": "Archives",
        "已选择": "Selected",
        "运行中": "Running",
        "未知": "Unknown",
        "进度": "Progress",
        "释放内存": "Free Up RAM",
        "释放可清除空间": "Free Up Purgeable Space",
        "运行维护脚本": "Run Maintenance Scripts",
        "验证启动磁盘": "Verify Startup Disk",
        "加速邮件": "Speed Up Mail",
        "重建启动服务": "Rebuild Launch Services",
        "重建 Spotlight 索引": "Reindex Spotlight",
        "刷新 DNS 缓存": "Flush DNS Cache",
        "精简 Time Machine 快照": "Thin Time Machine Snapshots",
    ]

    /// German v1 translates static source keys. Interpolated source keys retain
    /// their original English expression, including its singular/plural logic.
    private static let germanFallbacks: [String: String] = [
        "1 - 3 个月": "1 bis 3 Monate",
        "3 - 6 个月": "3 bis 6 Monate",
        "30 天内不再显示": "30 Tage ausblenden",
        "6 个月 - 1 年": "6 Monate bis 1 Jahr",
        "AI 工具缓存": "KI-Werkzeug-Caches",
        "AI 编码工具的缓存（Claude、Codex）；不含历史与会话。": "Caches von KI-Programmierwerkzeugen (Claude, Codex). Verlauf und Sitzungen bleiben erhalten.",
        "CPU": "CPU",
        "GPU 使用率": "GPU-Auslastung",
        "GitHub 返回了无法识别的响应。": "Unerwartete Antwort von GitHub.",
        "Homebrew 返回了无法识别的响应。": "Unerwartete Antwort von Homebrew.",
        "IDE 与编辑器缓存": "IDE- und Editor-Caches",
        "Internet 插件": "Internet-Plug-ins",
        "PDF": "PDFs",
        "Safari 扩展": "Safari-Erweiterungen",
        "Safari 扩展不能在本应用内开启、关闭或删除，以免破坏宿主应用的签名。请在 Safari 设置中管理它们。": "Safari-Erweiterungen können hier nicht aktiviert, deaktiviert oder gelöscht werden, da dies die Signatur der zugehörigen App beschädigen würde. Verwalte sie in den Safari-Einstellungen.",
        "Spotlight 的整个搜索索引会被清除并重建。数小时内 Spotlight 搜索可能返回空结果（主目录越大耗时越久），系统搜索和智能文件夹也会受影响。": "Der gesamte Spotlight-Suchindex wird gelöscht und neu erstellt. Die Suche liefert mehrere Stunden lang keine Ergebnisse, bei großen Benutzerordnern auch länger. Systemsuche und intelligente Ordner sind ebenfalls betroffen.",
        "URL Scheme": "URL-Schema",
        "Xcode 垃圾": "Xcode-Dateireste",
        "iOS 设备备份": "iOS-Gerätebackups",
        "iPhone 和 iPad 的本地备份。": "Lokale Backups von iPhone und iPad.",
        "macOS 的“哪类文件由哪个应用打开”数据库会被清除并重建。完成前（通常数小时），双击文件可能失败或打开错误应用，默认应用设置可能重置，Spotlight 启动应用也可能不可用。重启可加快恢复。": "Die macOS-Datenbank zur Zuordnung von Dateitypen zu Apps wird gelöscht und neu erstellt. Bis zum Abschluss (oft mehrere Stunden) können Doppelklicks fehlschlagen oder die falsche App öffnen, Standard-Apps zurückgesetzt werden und App-Starts über Spotlight fehlschlagen. Ein Neustart beschleunigt dies.",
        "macOS 诊断日志。": "macOS-Diagnoseprotokolle.",
        "npm、Cargo、pip、Homebrew、Gradle 的可重建缓存。": "Neu erzeugbare Caches von npm, Cargo, pip, Homebrew und Gradle.",
        "~/Library/Logs/MacClean/operations.log — 30 天后自动清理": "~/Library/Logs/MacClean/operations.log — Einträge werden nach 30 Tagen entfernt",
        "“邮件”应用的搜索索引会从头重建。重建完成前，邮件搜索和未读数可能不准确（大型邮箱通常需 10–30 分钟）。": "Der Suchindex von Mail wird neu erstellt. Suche und Anzahl ungelesener Nachrichten können bis zum Abschluss falsch sein (bei großen Postfächern meist 10–30 Minuten).",
        "一切就绪！": "Alles bereit!",
        "一键清理": "Bereinigung mit einem Klick",
        "上一级": "Eine Ebene höher",
        "下一步": "Weiter",
        "下载": "Herunterladen",
        "不可写": "nicht beschreibbar",
        "不能排除整个 /Volumes。": "Der gesamte Bereich /Volumes kann nicht ausgeschlossen werden.",
        "不能排除整个主目录。": "Dein gesamter Benutzerordner kann nicht ausgeschlossen werden.",
        "主题": "Design",
        "仅显示错误": "Nur Fehler",
        "仅移除 macOS 已标记可清理的 Time Machine 本地快照；不会删除你主动需要的内容。": "Lokale Time-Machine-Schnappschüsse, die macOS bereits zur Bereinigung markiert hat, werden entfernt. Aktiv benötigte Daten werden nicht gelöscht.",
        "仍要运行": "Trotzdem ausführen",
        "从大到小": "Größte zuerst",
        "从小到大": "Kleinste zuerst",
        "代码": "Quellcode",
        "代码编辑器的缓存（Cursor、Antigravity 等）。": "Caches von Code-Editoren wie Cursor und Antigravity.",
        "以开源方式让你的 Mac 保持干净、快速和安全。": "Die Open-Source-Lösung, um deinen Mac sauber, schnell und sicher zu halten.",
        "优化": "Optimierung",
        "优化你的 Mac": "Deinen Mac optimieren",
        "会产生几分钟磁盘活动。该操作为只读，无论结果如何都不会更改磁盘内容。": "Einige Minuten Festplattenaktivität. Nur lesender Zugriff: Unabhängig vom Ergebnis wird nichts auf der Festplatte geändert.",
        "会删除本地 Time Machine 快照以释放空间。远程或备份盘上的快照不受影响，你仍可从 Time Machine 备份恢复。": "Lokale Time-Machine-Schnappschüsse werden gelöscht, um Speicherplatz freizugeben. Schnappschüsse auf entfernten oder Backup-Laufwerken bleiben erhalten; eine Wiederherstellung aus dem Time-Machine-Backup ist weiterhin möglich.",
        "你的 Mac 很干净！": "Dein Mac ist sauber!",
        "你选择的项目已在废纸篓中——需要时可以恢复。若要彻底删除，请打开“废纸篓”模块并清空。": "Deine ausgewählten Objekte liegen im Papierkorb. Stelle benötigte Objekte wieder her. Zum endgültigen Löschen öffne Papierkörbe und leere sie.",
        "使用渐进式 SHA-256 哈希检测\n查找重复文件": "Doppelte Dateien durch schrittweise\nSHA-256-Prüfung finden",
        "保留": "BEHALTEN",
        "修复 Finder 的文件类型与应用打开方式数据库": "Finders Datenbank zur Zuordnung von Dateitypen zu Anwendungen reparieren",
        "偏好设置面板": "Systemeinstellungsmodule",
        "充电中": "Wird geladen",
        "全部": "Alle",
        "全部展开": "Alle aufklappen",
        "全部折叠": "Alle zuklappen",
        "关于": "Über die App",
        "关闭": "deaktivieren",
        "其他": "Sonstige",
        "内存": "Arbeitsspeicher",
        "内存使用率": "Speicherauslastung",
        "内存压力过高": "Hoher Speicherdruck",
        "内容已更改": "Inhalt geändert",
        "出于安全考虑，已拒绝移除此项目。": "Dieses Objekt wurde aus Sicherheitsgründen abgelehnt.",
        "分区": "Bereich",
        "切换后会立即应用到主界面和菜单栏小组件。": "Änderungen gelten sofort im Hauptfenster und im Menüleisten-Widget.",
        "刚刚": "gerade eben",
        "删除此关联（自动备份当前版本）": "Entfernen (automatische Sicherung erstellt)",
        "删除重复项": "Duplikate entfernen",
        "刷新 DNS 缓存": "DNS-Cache leeren",
        "刷新": "Aktualisieren",
        "前往“隐私与安全性 → 完全磁盘访问权限”": "Öffne Datenschutz & Sicherheit → Festplattenvollzugriff",
        "加速": "Geschwindigkeit",
        "加速邮件": "Mail beschleunigen",
        "包管理器缓存": "Paketmanager-Caches",
        "占用空间最多的文件。": "Die Dateien mit dem größten Speicherbedarf.",
        "占用资源": "Ressourcenintensive Apps",
        "卸载": "Deinstallieren",
        "卸载器": "Deinstallation",
        "压缩包": "Archive",
        "发现新版本": "Update verfügbar",
        "发现的垃圾": "Dateireste gefunden",
        "发生未知错误": "Ein unbekannter Fehler ist aufgetreten",
        "发行说明": "Versionshinweise",
        "取消": "Abbrechen",
        "受保护的系统应用——无法移除": "Geschützte System-App: Kann nicht entfernt werden",
        "受保护路径": "geschützter Pfad",
        "受保护，无法退出": "Geschützt: Kann nicht beendet werden",
        "受限": "Eingeschränkt",
        "只能排除主目录或 /Volumes 下的文件夹。": "Nur Ordner im Benutzerordner oder unter /Volumes können ausgeschlossen werden.",
        "可回收": "können freigegeben werden",
        "可用磁盘空间": "Freier Speicherplatz",
        "可能带来持续数小时的影响——将打开确认窗口": "Hat Auswirkungen über mehrere Stunden und öffnet eine Bestätigung",
        "可视化磁盘使用情况": "Speicherbelegung darstellen",
        "可视化磁盘空间使用情况": "Speicherbelegung darstellen",
        "合并": "Zusammenführen",
        "合并所选副本？": "Ausgewählte Kopien zusammenführen?",
        "同一文件的相同副本。": "Identische Kopien derselben Datei.",
        "启动代理": "Launch Agents",
        "启动守护进程": "Launch Daemons",
        "回收 Docker 空间": "Docker-Speicherplatz freigeben",
        "图片": "Bilder",
        "在 Finder 中显示": "Im Finder anzeigen",
        "在 Finder 中查看配置文件": "Konfiguration im Finder anzeigen",
        "在 GitHub 上浏览代码库": "Quellcode auf GitHub ansehen",
        "在屏幕顶部实时显示 CPU、内存、磁盘、电池和网络状态。点击可展开浮窗。": "Aktuelle CPU-, Speicher-, Festplatten-, Batterie- und Netzwerkwerte am oberen Bildschirmrand. Zum Öffnen der Übersicht anklicken.",
        "在监控位置检测到新的可执行文件": "Neue ausführbare Datei an einem überwachten Ort erkannt",
        "在磁盘上发现的已知恶意文件。": "Bekannte schädliche Dateien auf der Festplatte.",
        "在系统设置中打开": "In den Systemeinstellungen öffnen",
        "在系统设置中打开类别": "Kategorie in den Systemeinstellungen öffnen",
        "复制": "Kopieren",
        "复制全部": "Alles kopieren",
        "复制升级命令": "Update-Befehl kopieren",
        "复制路径": "Pfad kopieren",
        "外观": "Erscheinungsbild",
        "大型个人目录可能需要几分钟扫描": "Bei großen Benutzerordnern kann dieser Scan mehrere Minuten dauern",
        "大小": "Größe",
        "大文件": "Große Dateien",
        "大文件与旧文件": "Große und alte Dateien",
        "失效的登录项": "Ungültige Anmeldeobjekte",
        "失败或孤立下载留下的文件。": "Reste fehlgeschlagener oder verwaister Downloads.",
        "好": "OK",
        "存储空间严重不足": "Speicherplatz kritisch",
        "安全擦除": "Sicher löschen",
        "安全擦除文件，使其无法恢复": "Dateien sicher und unwiederbringlich löschen",
        "安装包": "Installationsdateien",
        "完全磁盘访问权限": "Festplattenvollzugriff",
        "完成": "Fertig",
        "完整日志：~/Library/Logs/MacClean/operations.log": "Vollständiges Protokoll: ~/Library/Logs/MacClean/operations.log",
        "实时系统状态": "Aktuelle Systemwerte",
        "将当前内容复制到剪贴板，可粘贴到 GitHub issue 中": "Sichtbare Einträge in die Zwischenablage kopieren, um sie in eine GitHub-Fehlermeldung einzufügen",
        "将文件拖放到此处进行粉碎": "Ziehe Dateien zum Vernichten hierher",
        "将模块渐变背景替换为中性的深色背景，以提升可读性。": "Farbverläufe der Module für bessere Lesbarkeit durch einen neutralen dunklen Hintergrund ersetzen.",
        "尚未排除任何文件夹。": "Noch keine Ordner ausgeschlossen.",
        "屏幕录制": "Bildschirmaufnahme",
        "展开": "Aufklappen",
        "已不存在": "bereits entfernt",
        "已保存的 Wi-Fi": "Gespeicherte WLANs",
        "已停用": "Aus",
        "已删除应用留下的支持文件。": "Unterstützungsdateien bereits gelöschter Apps.",
        "已删除应用的残留文件": "Reste gelöschter Apps",
        "已删除用户数据": "Gelöschte Benutzer",
        "已发现文件": "Gefundene Dateien",
        "已取消——未授予管理员权限。": "Abgebrochen: Administratorzugriff wurde nicht gewährt.",
        "已启用": "Ein",
        "已复制": "Kopiert",
        "已是最新": "Aktuell",
        "已清理": "bereinigt",
        "已移到废纸篓": "In den Papierkorb verschoben",
        "已移除用户账户留下的数据。": "Zurückgebliebene Daten entfernter Benutzerkonten.",
        "已连接": "Verbunden",
        "已选择": "Ausgewählt",
        "已选择待清理": "zur Bereinigung ausgewählt",
        "已防护": "Geschützt",
        "干净": "Bereinigen",
        "平衡": "Ausgewogen",
        "应用": "Anwendungen",
        "应用临时文件，下次启动会重新生成。": "Temporäre App-Dateien. Werden beim nächsten Start neu erstellt.",
        "应用二进制中未使用的 CPU 架构切片。": "Ungenutzte CPU-Architekturen in App-Binärdateien.",
        "应用内未使用的本地化语言资源。": "Ungenutzte, mit Apps ausgelieferte Übersetzungen.",
        "应用写入的诊断日志。": "Von deinen Apps geschriebene Diagnoseprotokolle.",
        "应用包中未找到通用 Mach-O 二进制文件": "Keine universellen Mach-O-Binärdateien im App-Paket gefunden.",
        "应用已打开": "App geöffnet",
        "应用更新": "App-Updates",
        "应用权限": "App-Berechtigungen",
        "应用程序": "Anwendungen",
        "废纸篓": "Papierkörbe",
        "废纸篓为空": "Papierkorb ist leer",
        "建议": "Empfehlungen",
        "开启": "aktivieren",
        "开始使用": "Los geht’s",
        "强制退出": "Sofort beenden",
        "强制退出前会要求确认": "Sofortiges Beenden erfordert zuerst eine Bestätigung",
        "当前位于废纸篓中的项目。": "Objekte, die sich derzeit im Papierkorb befinden.",
        "彻底移除应用": "Apps vollständig entfernen",
        "彻底移除应用及其残留文件": "Apps und ihre Restdateien vollständig entfernen",
        "待清理": "zu bereinigen",
        "忘记": "Entfernen",
        "忘记所选": "Auswahl entfernen",
        "忘记所选网络？": "Ausgewählte Netzwerke entfernen?",
        "快速": "Schnell",
        "性能": "Leistung",
        "恢复默认": "Auf Standardwerte zurücksetzen",
        "恶意软件": "Schadsoftware",
        "恶意软件扫描": "Schadsoftware-Scan",
        "恶意软件清理": "Schadsoftware entfernen",
        "所有应用均为最新": "Alle Apps sind aktuell",
        "所选副本会保留在原位并转为克隆，仅释放重复占用的空间，不删除任何文件。": "Ausgewählte Kopien bleiben als Klone an ihrem Ort. Nur der zusätzlich belegte Speicher wird freigegeben; nichts wird gelöscht.",
        "所选副本会被移到废纸篓，每组保留一个原件。": "Ausgewählte Kopien werden in den Papierkorb verschoben. Ein Original je Gruppe bleibt erhalten.",
        "打开 Safari 设置": "Safari-Einstellungen öffnen",
        "打开活动日志，查看每个错误并复制详情用于反馈问题": "Öffne das Aktivitätsprotokoll, um alle Fehler zu sehen und Details für eine Fehlermeldung zu kopieren",
        "打开系统设置": "Systemeinstellungen öffnen",
        "打开设置": "Einstellungen öffnen",
        "执行 macOS 内置的每日、每周和每月维护任务": "Die integrierten täglichen, wöchentlichen und monatlichen macOS-Wartungsroutinen ausführen",
        "扩展": "Erweiterungen",
        "扫描 Mac 中的垃圾文件、恶意威胁\n和性能问题": "Prüfe deinen Mac auf Dateireste, Schadsoftware\nund Leistungsprobleme",
        "扫描": "Scannen",
        "扫描完成——没有需要清理的内容": "Scan abgeschlossen: Nichts zu bereinigen",
        "扫描病毒、广告软件和其他威胁": "Auf Viren, Adware und weitere Bedrohungen prüfen",
        "折叠": "Zuklappen",
        "报告问题": "Problem melden",
        "指向已不存在应用的登录项。": "Anmeldeobjekte, deren Apps nicht mehr vorhanden sind.",
        "按名称": "Name",
        "按应用查看持有哪些隐私权限。这是只读列表——按钮会打开系统设置。本应用无法关闭权限。": "Zeigt die Datenschutzberechtigungen jeder App. Diese Liste ist schreibgeschützt; die Schaltflächen öffnen die Systemeinstellungen. Mac Sai kann keine Berechtigung deaktivieren.",
        "损坏或孤立的偏好设置文件。": "Beschädigte oder verwaiste Einstellungsdateien.",
        "损坏的偏好设置": "Beschädigte Einstellungen",
        "排序": "Sortierung",
        "排序方式": "Sortieren nach",
        "排除": "Ausschließen",
        "排除文件夹": "Ausgeschlossene Ordner",
        "提交错误报告和功能请求": "Fehlermeldungen und Funktionswünsche",
        "搜索应用...": "Apps suchen …",
        "搜索文件类型或应用...": "Dateityp oder App suchen …",
        "搜索语言": "Sprachen suchen",
        "文件": "Dateien",
        "文件夹": "Ordner",
        "文件打开方式": "Dateizuordnungen",
        "文件粉碎": "Dateien vernichten",
        "文档": "Dokumente",
        "文档版本": "Dokumentversionen",
        "无法写入 plist": "plist-Datei kann nicht geschrieben werden",
        "无法列出哪些应用持有哪些权限。仍可通过下方按钮打开系统设置。": "Diese App kann nicht auflisten, welche Apps welche Berechtigungen besitzen. Mit den Schaltflächen unten kannst du weiterhin die Systemeinstellungen öffnen.",
        "无法更新已保存的 Wi-Fi 网络。": "Gespeicherte WLAN-Netzwerke konnten nicht aktualisiert werden.",
        "无法添加该文件夹。": "Dieser Ordner konnte nicht hinzugefügt werden.",
        "无法读取 plist": "plist-Datei kann nicht gelesen werden",
        "无法读取权限数据库": "Berechtigungsdatenbank konnte nicht gelesen werden",
        "无法退出受保护的进程。": "Dieser Prozess ist geschützt und kann nicht beendet werden.",
        "无线接口名称无效，已中止操作。": "Der Name der WLAN-Schnittstelle war ungültig. Die Aktion wurde abgebrochen.",
        "日志为空。尚未执行过清理。": "Das Protokoll ist leer. Bisher wurde nichts bereinigt.",
        "旧文件": "Alte Dateien",
        "旧更新文件": "Alte Updates",
        "旧的自动保存文档版本。": "Alte automatisch gespeicherte Dokumentversionen.",
        "显示宿主应用": "Zugehörige App anzeigen",
        "智能扫描": "Intelligenter Scan",
        "更改权限只能在系统设置中完成。": "Berechtigungen können nur in den Systemeinstellungen geändert werden.",
        "更新": "Aktualisieren",
        "更新后遗留的安装包。": "Nach Updates zurückgebliebene Installationspakete.",
        "更新日志和历史版本": "Änderungsprotokoll und frühere Versionen",
        "曾经挂载但已不再需要的磁盘映像。": "Früher eingebundene und vergessene Disk-Images.",
        "曾被换出的应用回到前台时可能需要片刻恢复。": "Apps mit ausgelagerten Speicherseiten können beim Wechsel in den Vordergrund kurz verzögert reagieren.",
        "最近 1 个月": "Letzter Monat",
        "最近清理": "Kürzlich bereinigt",
        "最近项目列表和其他隐私痕迹。": "Listen zuletzt verwendeter Objekte und weitere Datenschutzspuren.",
        "未下载完成的文件。": "Teilweise heruntergeladene Dateien.",
        "未使用": "Ungenutzt",
        "未使用的磁盘映像": "Ungenutzte Disk-Images",
        "未保存的工作可能会丢失。": "Nicht gespeicherte Arbeit kann verloren gehen.",
        "未列出任何 Safari 扩展": "Keine Safari-Erweiterungen aufgeführt",
        "未列出任何应用。": "Keine Apps aufgeführt.",
        "未发现垃圾": "Keine Dateireste gefunden",
        "未发现垃圾、威胁或性能问题": "Keine Dateireste, Bedrohungen oder Leistungsprobleme gefunden",
        "未发现隐私痕迹": "Keine Datenschutzspuren gefunden",
        "未在应用包中找到辅助组件": "Hilfsprogramm nicht im App-Paket gefunden",
        "未完成下载": "Unvollständige Downloads",
        "未找到 Docker 命令行工具。请确认已安装 Docker Desktop。": "Docker-Kommandozeilenprogramm nicht gefunden. Stelle sicher, dass Docker Desktop installiert ist.",
        "未找到 Wi-Fi 硬件。": "Keine WLAN-Hardware gefunden.",
        "未找到关联文件": "Keine zugehörigen Dateien gefunden",
        "未找到大文件或旧文件": "Keine großen oder alten Dateien gefunden",
        "未找到第三方扩展、插件或偏好设置面板。": "Keine Erweiterungen, Plug-ins oder Systemeinstellungsmodule von Drittanbietern gefunden.",
        "未找到邮件索引——邮件可能使用了不同的版本目录。": "Mail-Nachrichtenindex nicht gefunden. Mail verwendet möglicherweise einen anderen Versionsordner.",
        "未找到重复文件": "Keine Duplikate gefunden",
        "未找到附件": "Keine Anhänge gefunden",
        "未找到项目": "Keine Objekte gefunden",
        "未检测到威胁": "Keine Bedrohungen erkannt",
        "未注册": "nicht registriert",
        "未知": "Unbekannt",
        "未知应用": "Unbekannte App",
        "未知错误": "Unbekannter Fehler",
        "未选择任何项目": "Nichts ausgewählt",
        "权限总览": "Berechtigungen",
        "查找大于 50 MB 且最近未访问的文件": "Dateien über 50 MB finden, auf die zuletzt nicht zugegriffen wurde",
        "查找并移除系统缓存、日志、\n语言文件和其他垃圾": "System-Caches, Protokolle, Sprachdateien\nund weitere Dateireste finden und entfernen",
        "查找来自邮件、Outlook 和 Spark 的缓存邮件附件": "Zwischengespeicherte E-Mail-Anhänge aus Mail, Outlook und Spark finden",
        "查找重复文件": "Doppelte Dateien finden",
        "查看占用 CPU 和内存的应用并强制退出": "Apps mit hoher CPU- und Speicherauslastung anzeigen und sofort beenden",
        "查看发布页": "Veröffentlichung anzeigen",
        "查看日志": "Protokoll anzeigen",
        "查看第三方偏好设置面板、Internet 插件和 Safari 扩展。用户安装的面板和插件可移到废纸篓。": "Prüfe Systemeinstellungsmodule von Drittanbietern, Internet-Plug-ins und Safari-Erweiterungen. Vom Benutzer installierte Module und Plug-ins können in den Papierkorb verschoben werden.",
        "标记为“保留”的行受保护，只会删除勾选的副本。": "Mit BEHALTEN markierte Zeilen sind geschützt. Nur ausgewählte Kopien werden gelöscht.",
        "检查可用的应用更新": "Nach verfügbaren App-Updates suchen",
        "检查启动磁盘的文件系统完整性": "Dateisystemintegrität des Startvolumes prüfen",
        "检查更新": "Nach Updates suchen",
        "检测并移除威胁": "Bedrohungen erkennen und entfernen",
        "模式": "Modus",
        "正在分析应用支持目录...": "Application Support wird analysiert …",
        "正在分析系统...": "System wird analysiert …",
        "正在分析结果...": "Ergebnisse werden analysiert …",
        "正在分析附件...": "Anhänge werden analysiert …",
        "正在加载项目...": "Objekte werden geladen …",
        "正在卸载…": "Wird deinstalliert …",
        "正在发现已安装应用...": "Installierte Apps werden gesucht …",
        "正在完成...": "Wird abgeschlossen …",
        "正在完成扫描...": "Scan wird abgeschlossen …",
        "正在并行哈希候选文件...": "Hashwerte möglicher Duplikate werden parallel berechnet …",
        "正在开始清理...": "Bereinigung wird gestartet …",
        "正在恢复默认…": "Wird zurückgesetzt …",
        "正在扫描 Apple Mail...": "Apple Mail wird geprüft …",
        "正在扫描 Chrome 数据...": "Chrome-Daten werden geprüft …",
        "正在扫描 Firefox 数据...": "Firefox-Daten werden geprüft …",
        "正在扫描 Outlook...": "Outlook wird geprüft …",
        "正在扫描 Safari 数据...": "Safari-Daten werden geprüft …",
        "正在扫描 Spark...": "Spark wird geprüft …",
        "正在扫描...": "Scan läuft …",
        "正在扫描个人目录...": "Benutzerordner wird geprüft …",
        "正在扫描启动守护进程...": "Launch Daemons werden geprüft …",
        "正在扫描用户废纸篓...": "Benutzer-Papierkorb wird geprüft …",
        "正在扫描用户缓存...": "Benutzer-Caches werden geprüft …",
        "正在扫描磁盘...": "Festplatte wird geprüft …",
        "正在扫描系统日志...": "Systemprotokolle werden geprüft …",
        "正在扫描缓存...": "Caches werden geprüft …",
        "正在按大小分组文件...": "Dateien werden nach Größe gruppiert …",
        "正在整理结果...": "Ergebnisse werden gruppiert …",
        "正在查找关联文件...": "Zugehörige Dateien werden gesucht …",
        "正在查找扩展…": "Erweiterungen werden gesucht …",
        "正在检查…": "Wird geprüft …",
        "正在检查偏好设置...": "Einstellungen werden geprüft …",
        "正在检查启动代理...": "Launch Agents werden geprüft …",
        "正在检查外接驱动器...": "Externe Laufwerke werden geprüft …",
        "正在检查已知恶意软件特征...": "Bekannte Schadsoftware-Signaturen werden geprüft …",
        "正在检查文件大小...": "Dateigrößen werden geprüft …",
        "正在检查更新...": "Nach Updates wird gesucht …",
        "正在检查浏览器扩展...": "Browser-Erweiterungen werden geprüft …",
        "正在检查登录项...": "Anmeldeobjekte werden geprüft …",
        "正在检查系统痕迹...": "Systemspuren werden geprüft …",
        "正在检查访问日期...": "Zugriffszeitpunkte werden geprüft …",
        "正在检查语言文件...": "Sprachdateien werden geprüft …",
        "正在检测已安装语言…": "Installierte Sprachen werden erkannt …",
        "正在清理你的 Mac...": "Dein Mac wird bereinigt …",
        "正在粉碎文件...": "Dateien werden vernichtet …",
        "正在计算大小...": "Größen werden berechnet …",
        "正在读取已保存的网络…": "Gespeicherte Netzwerke werden gelesen …",
        "正在读取权限…": "Berechtigungen werden gelesen …",
        "正在读取进程…": "Prozesse werden gelesen …",
        "残留下载文件": "Fehlgeschlagene Downloads",
        "每组都会保留一个副本，且永远不会被移除。": "Eine Kopie jeder Gruppe bleibt erhalten und kann niemals entfernt werden.",
        "永久删除": "Endgültig löschen",
        "没有可显示的应用": "Keine Apps anzuzeigen",
        "没有可用的备份": "Keine Sicherungen verfügbar",
        "没有已保存的 Wi-Fi 网络": "Keine gespeicherten WLAN-Netzwerke",
        "没有找到匹配的结果": "Keine passenden Ergebnisse",
        "没有自定义的文件打开方式": "Keine benutzerdefinierten Dateizuordnungen",
        "没有记录到错误。": "Keine Fehler protokolliert.",
        "活动日志": "Aktivitätsprotokoll",
        "派生数据、归档和模拟器缓存。": "Abgeleitete Daten, Archive und Simulator-Caches.",
        "浅色": "Hell",
        "浏览历史和跟踪数据；Cookie 与会话会保留。": "Browserverlauf und Tracking-Daten. Cookies und Sitzungen bleiben erhalten.",
        "浏览器和其他网络应用会在下次请求时重新解析主机名，影响通常只有毫秒级。": "Browser und andere Netzwerk-Apps lösen Hostnamen bei der nächsten Anfrage neu auf. Die Auswirkung beträgt Millisekunden.",
        "浏览器隐私": "Browser-Datenschutz",
        "深度": "Gründlich",
        "深色": "Dunkel",
        "添加文件夹…": "Ordner hinzufügen …",
        "清理": "Bereinigung",
        "清理所选项目": "Auswahl bereinigen",
        "清理未使用的 Docker 镜像、已停止的容器和构建缓存": "Ungenutzte Docker-Images, gestoppte Container und Build-Cache entfernen",
        "清理浏览器数据、历史记录、Cookie 和系统痕迹": "Browserdaten, Verlauf, Cookies und Systemspuren bereinigen",
        "清理缓存、日志和临时文件": "Caches, Protokolle und temporäre Dateien bereinigen",
        "清理非活动内存，为当前应用释放更多空间": "Inaktiven Speicher freigeben, damit aktive Apps mehr Arbeitsspeicher nutzen können",
        "清空废纸篓": "Papierkorb leeren",
        "清空废纸篓？": "Papierkorb leeren?",
        "清空所有废纸篓位置，包括外接驱动器": "Alle Papierkörbe einschließlich externer Laufwerke leeren",
        "清除本地 DNS 缓存并强制重新解析": "Lokalen DNS-Cache leeren und neue Abfragen erzwingen",
        "清除缓存、偏好设置和保存的状态，保留应用本身。": "Entfernt Caches, Einstellungen und gespeicherten Zustand. Die App bleibt installiert.",
        "源代码": "Quellcode",
        "点击“扫描”以可视化磁盘使用情况": "Klicke auf Scannen, um die Speicherbelegung darzustellen",
        "点击“智能扫描”即可一键清理 Mac，也可以在侧边栏探索各个模块。": "Klicke auf Intelligenter Scan, um deinen Mac mit einem Klick zu bereinigen, oder erkunde die einzelnen Module in der Seitenleiste.",
        "点击上方按钮检查更新": "Klicke oben, um nach Updates zu suchen",
        "版本历史": "Versionsverlauf",
        "用户": "Benutzer",
        "用户日志文件": "Benutzer-Protokolldateien",
        "用户缓存文件": "Benutzer-Cache-Dateien",
        "由 macOS 管理的缓存，会自动重建。": "Von macOS verwaltete Caches. Werden automatisch neu erstellt.",
        "电池": "Batterie",
        "电池循环次数较高": "Hohe Anzahl an Ladezyklen",
        "电池温度": "Batterietemperatur",
        "界面语言": "Sprache der Oberfläche",
        "登录时启动": "Beim Anmelden starten",
        "登录项": "Anmeldeobjekte",
        "相机": "Kamera",
        "磁盘": "Festplatte",
        "磁盘映像": "Disk-Images",
        "移到废纸篓": "In den Papierkorb verschieben",
        "移到废纸篓？": "In den Papierkorb verschieben?",
        "移除": "Entfernen",
        "移除不再使用的已保存网络，减少被追踪的可能。需要管理员权限。": "Entferne nicht mehr genutzte Netzwerke, um deine Tracking-Angriffsfläche zu verkleinern. Administratorzugriff ist erforderlich.",
        "移除背景颜色": "Hintergrundfarben entfernen",
        "稍后": "Später",
        "空间透视": "Speicherübersicht",
        "第三方": "Drittanbieter",
        "筛选": "Filter",
        "粉碎": "Vernichten",
        "精简 Time Machine 快照": "Time-Machine-Schnappschüsse reduzieren",
        "精简后应用包无法再通过 codesign --verify": "App-Paket besteht nach dem Verkleinern codesign --verify nicht mehr.",
        "系统垃圾": "Systemmüll",
        "系统日志文件": "System-Protokolldateien",
        "系统缓存文件": "System-Cache-Dateien",
        "系统隐私": "System-Datenschutz",
        "组件状态：": "Widget-Status:",
        "继续": "Fortfahren",
        "维护": "Wartung",
        "缩减本地 Time Machine 快照以回收磁盘空间": "Lokale Time-Machine-Schnappschüsse reduzieren, um Speicherplatz freizugeben",
        "自动化": "Automatisierung",
        "自动检查更新": "Automatisch nach Updates suchen",
        "英文、基础资源、中文、俄文和德文会始终保留。已勾选的语言会保留；未勾选的语言文件可由“系统垃圾”移除。": "Englisch, Basisressourcen, Chinesisch, Russisch und Deutsch bleiben immer erhalten. Markierte Sprachen werden behalten; nicht markierte Sprachdateien können durch Systemmüll entfernt werden.",
        "菜单栏显示": "Anzeige in der Menüleiste",
        "表格": "Tabellen",
        "视频": "Videos",
        "设置": "Einstellungen",
        "设置…": "Einstellungen …",
        "该任务没有可执行的系统命令": "Aufgabe hat keinen Systembefehl",
        "该路径已被现有排除项覆盖。": "Dieser Pfad ist bereits durch einen vorhandenen Ausschluss abgedeckt.",
        "该进程已不再运行。": "Dieser Prozess läuft nicht mehr.",
        "语言": "Sprache",
        "语言文件": "Sprachdateien",
        "语言清理": "Sprachdateien bereinigen",
        "请从侧边栏选择一个模块": "Wähle ein Modul in der Seitenleiste",
        "请至少勾选一个要清理的项目": "Wähle mindestens ein Objekt zur Bereinigung aus",
        "请选择绝对路径。": "Wähle einen absoluten Pfad.",
        "请重新扫描，勾选要移除的项目，然后点击“清理”。": "Wiederhole den Scan, markiere die zu entfernenden Objekte und klicke auf Bereinigen.",
        "超过 1 年": "Älter als 1 Jahr",
        "跟随系统": "System",
        "跨卷": "anderes Volume",
        "跳过此版本": "Diese Version überspringen",
        "输入的二进制文件不是通用 Mach-O": "Eingabedatei ist keine universelle Mach-O-Binärdatei.",
        "运行 docker system prune，删除未使用的镜像、已停止的容器、未使用的网络和构建缓存。此操作不可撤销（不会进入废纸篓）。正在运行的容器、使用中的镜像和命名卷不受影响，磁盘映像 Docker.raw 也不会被直接删除。": "Führt docker system prune aus und entfernt ungenutzte Images, gestoppte Container, ungenutzte Netzwerke und Build-Cache. Dies ist unwiderruflich und verwendet keinen Papierkorb. Laufende Container, verwendete Images und benannte Volumes bleiben erhalten. Docker.raw wird niemals direkt gelöscht.",
        "运行中": "Läuft",
        "运行安全任务": "Sichere Aufgaben ausführen",
        "运行时间": "Betriebszeit",
        "运行此任务": "Diese Aufgabe ausführen",
        "运行系统维护任务，让 Mac 保持健康": "Systemwartung für einen funktionierenden Mac ausführen",
        "运行维护脚本": "Wartungsskripte ausführen",
        "返回": "Zurück",
        "返回起点": "Zurück zum Anfang",
        "还原": "Wiederherstellen",
        "还原版本": "Version wiederherstellen",
        "这台 Mac": "Dieser Mac",
        "进度": "Fortschritt",
        "退出": "Beenden",
        "退出监视器": "Monitor beenden",
        "选中的项目会移到废纸篓，如有需要仍可恢复。": "Ausgewählte Objekte werden in den Papierkorb verschoben, damit du sie bei Bedarf wiederherstellen kannst.",
        "选择一个应用以查看相关文件": "Wähle eine App, um ihre Dateien anzuzeigen",
        "选择应用图标旁显示的紧凑数值。GPU 或电池温度不可用时显示 --。": "Wähle den kompakten Wert neben dem App-Symbol. Nicht verfügbare GPU- oder Batteriesensoren werden als -- angezeigt.",
        "选择文件": "Dateien auswählen",
        "选择要从清理中排除的文件夹。": "Wähle einen Ordner, der von der Bereinigung ausgeschlossen werden soll.",
        "通常没有可见影响——这些脚本与 macOS 夜间自动运行的维护脚本相同。": "Keine sichtbaren Auswirkungen. Es sind dieselben Skripte, die macOS nachts selbst ausführt.",
        "通用": "Allgemein",
        "通用二进制": "Universal-Binärdateien",
        "通过精简低优先级本地快照回收可清除磁盘空间": "Löschbaren Speicherplatz durch Reduzieren lokaler Schnappschüsse mit niedriger Priorität freigeben",
        "邮件索引已移除。邮件将在下次启动时重建。": "Mail-Nachrichtenindex entfernt. Mail erstellt ihn beim nächsten Start neu.",
        "邮件附件": "E-Mail-Anhänge",
        "邮件附件的缓存副本。": "Gespeicherte Kopien von E-Mail-Anhängen.",
        "释放内存": "Arbeitsspeicher freigeben",
        "释放可清除空间": "Löschbaren Speicherplatz freigeben",
        "释放空间": "Speicherplatz freigeben",
        "重复文件": "Duplikate",
        "重复文件检测会使用 SHA-256 哈希每个候选文件。\n大型个人目录可能需要 5–15 分钟。": "Die Duplikaterkennung berechnet für jede mögliche Duplikatdatei einen SHA-256-Hash.\nBei großen Benutzerordnern kann dies 5–15 Minuten dauern.",
        "重建 Spotlight 搜索索引，提高搜索准确性": "Spotlight-Suchindex für genauere Suchergebnisse neu erstellen",
        "重建 Spotlight 索引": "Spotlight neu indexieren",
        "重建“邮件”数据库索引，以修复搜索和性能问题": "Mail-Datenbank neu indexieren, um Such- und Leistungsprobleme zu beheben",
        "重建启动服务": "Launch Services neu erstellen",
        "重新扫描": "Erneut scannen",
        "重新扫描启动项": "Startobjekte erneut prüfen",
        "重新检查": "Erneut prüfen",
        "重新读取已保存的网络": "Gespeicherte Netzwerke neu laden",
        "重新读取扩展列表": "Erweiterungsliste neu laden",
        "重新读取权限列表": "Berechtigungsliste neu laden",
        "重试": "Erneut versuchen",
        "错误": "Fehler",
        "长时间未打开的文件。": "Dateien, die du lange nicht geöffnet hast.",
        "防护": "Schutz",
        "隐私清理": "Datenschutz",
        "需要在“系统设置 → 登录项”中批准": "Freigabe unter Systemeinstellungen → Anmeldeobjekte erforderlich",
        "需要在“系统设置 → 通用 → 登录项”中批准": "Freigabe unter Systemeinstellungen → Allgemein → Anmeldeobjekte erforderlich",
        "需要完全磁盘访问权限": "Festplattenvollzugriff erforderlich",
        "需要完全磁盘访问权限才能列出应用": "Festplattenvollzugriff zum Auflisten der Apps erforderlich",
        "非 APFS 卷": "kein APFS-Volume",
        "非普通文件": "keine reguläre Datei",
        "音频": "Audio",
        "验证启动磁盘": "Startvolume prüfen",
        "高级": "ERWEITERT",
        "麦克风": "Mikrofon",
    ]

    private static let russianFallbacks: [String: String] = [
        "智能扫描": "Умное сканирование",
        "系统垃圾": "Системный мусор",
        "邮件附件": "Почтовые вложения",
        "废纸篓": "Корзины",
        "恶意软件清理": "Удаление угроз",
        "隐私清理": "Конфиденциальность",
        "已保存的 Wi-Fi": "Сохранённые сети Wi-Fi",
        "应用权限": "Разрешения приложений",
        "权限总览": "Обзор разрешений",
        "优化": "Оптимизация",
        "维护": "Обслуживание",
        "卸载器": "Удаление приложений",
        "扩展": "Расширения",
        "应用更新": "Обновления",
        "空间透视": "Карта диска",
        "大文件与旧文件": "Большие и старые файлы",
        "重复文件": "Дубликаты",
        "文件粉碎": "Уничтожение файлов",
        "设置": "Настройки",
        "清理": "Очистка",
        "防护": "Защита",
        "性能": "Производительность",
        "应用": "Приложения",
        "文件": "Файлы",
        "全部": "Все",
        "未使用": "Неиспользуемые",
        "第三方": "Сторонние",
        "快速": "Быстро",
        "平衡": "Сбалансированно",
        "深度": "Глубоко",
        "开启": "включить",
        "关闭": "отключить",
        "压缩包": "Архивы",
        "已选择": "Выбрано",
        "运行中": "Работает",
        "未知": "Неизвестно",
        "进度": "Ход выполнения",
        "可用磁盘空间": "Свободное место на диске",
        "GPU 使用率": "Загрузка GPU",
        "内存使用率": "Использование памяти",
        "电池温度": "Температура аккумулятора",
        "菜单栏显示": "Показатель в строке меню",
        "选择应用图标旁显示的紧凑数值。GPU 或电池温度不可用时显示 --。":
            "Выберите компактный показатель рядом со значком приложения. Если данные GPU или температуры аккумулятора недоступны, отображается --.",
        "释放内存": "Освободить оперативную память",
        "释放可清除空间": "Освободить место, доступное для очистки",
        "运行维护脚本": "Запустить скрипты обслуживания",
        "验证启动磁盘": "Проверить загрузочный диск",
        "加速邮件": "Ускорить Почту",
        "重建启动服务": "Перестроить Launch Services",
        "重建 Spotlight 索引": "Перестроить индекс Spotlight",
        "刷新 DNS 缓存": "Очистить кэш DNS",
        "精简 Time Machine 快照": "Проредить снимки Time Machine",
    ]
}
