import UIKit

@MainActor
final class KeyboardViewController: UIInputViewController {
    private var conveyorRows: [ConveyorRowView] = []
    private var displayLink: CADisplayLink?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.035, green: 0.04, blue: 0.05, alpha: 1)

        let root = UIStackView()
        root.axis = .vertical
        root.spacing = 7
        root.translatesAutoresizingMaskIntoConstraints = false

        let title = UILabel()
        title.text = "くるくる Move · UIKit"
        title.textColor = UIColor.white.withAlphaComponent(0.72)
        title.font = .systemFont(ofSize: 12, weight: .semibold)
        root.addArrangedSubview(title)

        let rows = [
            ["あ","い","う","え","お","か","き","く","け","こ","さ","し","す","せ","そ"],
            ["た","ち","つ","て","と","な","に","ぬ","ね","の","は","ひ","ふ","へ","ほ"],
            ["ま","み","む","め","も","や","ゆ","よ","ら","り","る","れ","ろ","わ","を","ん"]
        ]

        for index in rows.indices {
            let row = ConveyorRowView(
                keys: rows[index],
                direction: index == 1 ? -1 : 1,
                speed: index == 1 ? 46 : 54
            ) { [weak self] key in
                self?.textDocumentProxy.insertText(key)
            }
            conveyorRows.append(row)
            root.addArrangedSubview(row)
            row.heightAnchor.constraint(equalToConstant: 46).isActive = true
        }

        let controls = UIStackView()
        controls.axis = .horizontal
        controls.distribution = .fillProportionally
        controls.spacing = 6

        let globe = makeButton("🌐")
        globe.addAction(UIAction { [weak self] _ in self?.advanceToNextInputMode() }, for: .touchUpInside)
        let space = makeButton("空白")
        space.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText(" ") }, for: .touchUpInside)
        let delete = makeButton("⌫")
        delete.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.deleteBackward() }, for: .touchUpInside)
        let enter = makeButton("改行")
        enter.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText("\n") }, for: .touchUpInside)

        [globe, space, delete, enter].forEach {
            $0.heightAnchor.constraint(equalToConstant: 42).isActive = true
            controls.addArrangedSubview($0)
        }
        space.setContentHuggingPriority(.defaultLow, for: .horizontal)
        root.addArrangedSubview(controls)

        view.addSubview(root)
        NSLayoutConstraint.activate([
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -6)
        ])

        let height = view.heightAnchor.constraint(equalToConstant: 235)
        height.priority = .defaultHigh
        height.isActive = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimation()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        displayLink?.invalidate()
        displayLink = nil
    }

    private func startAnimation() {
        guard displayLink == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(tick(_:)))
        link.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 60, preferred: 60)
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    @objc private func tick(_ link: CADisplayLink) {
        let delta = max(0, min(link.targetTimestamp - link.timestamp, 0.05))
        for row in conveyorRows {
            row.advance(seconds: delta)
        }
    }

    private func makeButton(_ title: String) -> UIButton {
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseForegroundColor = .white
        config.baseBackgroundColor = UIColor(white: 1, alpha: 0.12)
        config.cornerStyle = .medium
        let button = UIButton(configuration: config)
        return button
    }
}

@MainActor
private final class ConveyorRowView: UIView {
    private let keys: [String]
    private let direction: CGFloat
    private let speed: CGFloat
    private let onTap: (String) -> Void
    private var phase: CGFloat = 0
    private var buttons: [UIButton] = []

    private let keyWidth: CGFloat = 44
    private let keyHeight: CGFloat = 42
    private let spacing: CGFloat = 8

    init(keys: [String], direction: CGFloat, speed: CGFloat, onTap: @escaping (String) -> Void) {
        self.keys = keys
        self.direction = direction
        self.speed = speed
        self.onTap = onTap
        super.init(frame: .zero)
        clipsToBounds = true

        for index in 0..<(keys.count * 3) {
            let key = keys[index % keys.count]
            var config = UIButton.Configuration.filled()
            config.title = key
            config.baseForegroundColor = .white
            config.baseBackgroundColor = UIColor(white: 1, alpha: 0.105)
            config.cornerStyle = .medium
            let button = UIButton(configuration: config)
            button.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
            button.addAction(UIAction { [weak self] _ in self?.onTap(key) }, for: .touchUpInside)
            addSubview(button)
            buttons.append(button)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func advance(seconds: CFTimeInterval) {
        let cycleWidth = CGFloat(keys.count) * (keyWidth + spacing)
        guard cycleWidth > 0 else { return }
        phase = (phase + speed * CGFloat(seconds)).truncatingRemainder(dividingBy: cycleWidth)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let stride = keyWidth + spacing
        let cycleWidth = CGFloat(keys.count) * stride
        let baseX = direction > 0 ? -cycleWidth + phase : -phase
        let y = (bounds.height - keyHeight) / 2

        for (index, button) in buttons.enumerated() {
            button.frame = CGRect(
                x: baseX + CGFloat(index) * stride,
                y: y,
                width: keyWidth,
                height: keyHeight
            )
        }
    }
}
