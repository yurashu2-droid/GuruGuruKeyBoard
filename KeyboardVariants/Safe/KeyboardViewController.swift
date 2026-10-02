import UIKit

@MainActor
final class KeyboardViewController: UIInputViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.06, green: 0.07, blue: 0.08, alpha: 1)

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 8
        root.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "くるくる Safe"
        label.textColor = .white
        label.font = .systemFont(ofSize: 13, weight: .bold)
        label.textAlignment = .center
        root.addArrangedSubview(label)

        for rowKeys in [["あ","か","さ","た","な"], ["は","ま","や","ら","わ"]] {
            let row = UIStackView()
            row.axis = .horizontal
            row.distribution = .fillEqually
            row.spacing = 6
            for key in rowKeys {
                let button = makeButton(key)
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

        let globe = makeButton("🌐")
        globe.addAction(UIAction { [weak self] _ in self?.advanceToNextInputMode() }, for: .touchUpInside)
        let space = makeButton("空白")
        space.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText(" ") }, for: .touchUpInside)
        let delete = makeButton("⌫")
        delete.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.deleteBackward() }, for: .touchUpInside)
        let enter = makeButton("改行")
        enter.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText("\n") }, for: .touchUpInside)

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

    private func makeButton(_ title: String) -> UIButton {
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
