import UIKit

/// Startup-isolation keyboard.
///
/// This target intentionally has no SwiftUI, Combine, azooKey, SPM package
/// dependency, timers, or dictionary resources. If this view launches on-device,
/// the extension's provisioning/signature path is valid and the crash is in the
/// richer keyboard stack. If iOS still immediately falls back to another
/// keyboard, the failure is outside that stack (typically extension signing).
@MainActor
final class KeyboardViewController: UIInputViewController {
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "くるくる SAFE 0.1.3"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.07, blue: 0.08, alpha: 1)

        let rows = [
            ["あ", "か", "さ", "た", "な"],
            ["は", "ま", "や", "ら", "わ"]
        ]

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false

        root.addArrangedSubview(statusLabel)

        for keys in rows {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 6

            for key in keys {
                let button = makeButton(title: key)
                button.addAction(UIAction { [weak self] _ in
                    self?.textDocumentProxy.insertText(key)
                }, for: .touchUpInside)
                row.addArrangedSubview(button)
            }
            root.addArrangedSubview(row)
        }

        let controls = UIStackView()
        controls.axis = .horizontal
        controls.distribution = .fillEqually
        controls.spacing = 6

        let globe = makeButton(title: "🌐")
        globe.addAction(UIAction { [weak self] _ in
            self?.advanceToNextInputMode()
        }, for: .touchUpInside)

        let space = makeButton(title: "空白")
        space.addAction(UIAction { [weak self] _ in
            self?.textDocumentProxy.insertText(" ")
        }, for: .touchUpInside)

        let delete = makeButton(title: "⌫")
        delete.addAction(UIAction { [weak self] _ in
            self?.textDocumentProxy.deleteBackward()
        }, for: .touchUpInside)

        let enter = makeButton(title: "改行")
        enter.addAction(UIAction { [weak self] _ in
            self?.textDocumentProxy.insertText("\n")
        }, for: .touchUpInside)

        [globe, space, delete, enter].forEach { controls.addArrangedSubview($0) }
        root.addArrangedSubview(controls)

        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -8)
        ])

        let height = view.heightAnchor.constraint(equalToConstant: 190)
        height.priority = .defaultHigh
        height.isActive = true
    }

    private func makeButton(title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.12)
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        button.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        return button
    }
}
