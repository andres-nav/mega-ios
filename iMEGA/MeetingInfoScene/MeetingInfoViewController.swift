import SwiftUI

@available(iOS 14.0, *)
final class MeetingInfoViewController: UIViewController {
    lazy var editBarButtonItem: UIBarButtonItem = UIBarButtonItem(title: Strings.Localizable.edit, style: .plain, target: self, action: #selector(editButtonItemTapped)
    )
    
    private(set) var viewModel: MeetingInfoViewModel

    lazy var hostingView = UIHostingController(rootView: MeetingInfoView(viewModel: viewModel))

    init(viewModel: MeetingInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSubview()
        navigationItem.title = Strings.Localizable.info
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.rightBarButtonItem = editBarButtonItem
    }
    
    @objc func editButtonItemTapped() {

    }
    
    private func configureSubview() {
        addChild(hostingView)
        view.addSubview(hostingView.view)
        hostingView.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingView.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hostingView.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            hostingView.view.widthAnchor.constraint(equalTo: view.widthAnchor),
            hostingView.view.heightAnchor.constraint(equalTo: view.heightAnchor)
        ])
    }
}