
import UIKit

class AccountCell: UITableViewCell {
    static let identifier = String(describing: AccountCell.self)

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var subtitleLabel: UILabel!
    @IBOutlet var codeLabel: UILabel!

    var account: HomeViewState.Account? {
        didSet {
            updateViews()
        }
    }

    func updateViews() {
        guard let account else { return }

        titleLabel.text = account.title
        subtitleLabel.text = account.subtitle
        if let code = account.code {
            codeLabel.text = splitCode(code)
        } else {
            codeLabel.text = "••• •••"
        }
    }
}

private func splitCode(_ code: String) -> String {
    guard case let len = code.count, len.isMultiple(of: 2) else { return code }
    return code.prefix(len / 2) + " " + code.suffix(len / 2)
}
