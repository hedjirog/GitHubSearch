import UIKit
import SafariServices
import ReactorKit
import RxSwift
import RxCocoa

class SearchViewController: UIViewController, StoryboardView {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var loadingView: UIView!

    let searchController = UISearchController(searchResultsController: nil)
    
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchController.obscuresBackgroundDuringPresentation = false
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    func bind(reactor: SearchViewReactor) {
        // Action
        searchController.searchBar.rx.text
            .throttle(0.5, scheduler: MainScheduler.instance)
            .map { Reactor.Action.inputQuery($0) }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)

        // State
        reactor.state
            .map { $0.repositories }
            .distinctUntilChanged { $0 == $1 }
            .bind(to: tableView.rx.items(cellIdentifier: "Cell")) { _, repository, cell in
                cell.textLabel?.text = repository.fullName
                cell.detailTextLabel?.text = repository.htmlURL.absoluteString
            }
            .disposed(by: disposeBag)
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "⚠️", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        searchController.present(alert, animated: true)
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let repository = reactor?.currentState.repositories[indexPath.row] else { return }
        let viewController = SFSafariViewController(url: repository.htmlURL)
        searchController.present(viewController, animated: true)
    }
}
