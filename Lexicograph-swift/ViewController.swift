import Foundation
import UIKit

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
	@lazy var wordSearchBar = UISearchBar(frame: CGRectMake(0.0, CGRectGetMaxY(UIApplication.sharedApplication().statusBarFrame), 0.0, 44.0))
	@lazy var suggestionsTableView = UITableView(frame: CGRectZero, style: .Plain)

	let textChecker = UITextChecker()

	var referenceLibraryViewController: UIReferenceLibraryViewController?

	var showingSuggestions: Bool = false
	var words: String[]
	var viewedWords: String[]

	init(nibName nibNameOrNil: String!, nibBundle nibBundleOrNil: NSBundle!) {
		words = String[]()
		viewedWords = String[]()

		super.init(nibName: nibName, bundle: nibBundle)

		suggestionsTableView.autoresizingMask = (.FlexibleWidth | .FlexibleRightMargin | .FlexibleHeight | .FlexibleBottomMargin);
		suggestionsTableView.delegate = self;
		suggestionsTableView.dataSource = self;

		wordSearchBar.autoresizingMask = (.FlexibleWidth | .FlexibleRightMargin)
		wordSearchBar.delegate = self;
		wordSearchBar.autocapitalizationType = .None;
		wordSearchBar.tintColor = UIColor(red: (194.0 / 255.0), green: (197.0 / 255.0), blue: (200.0 / 255.0), alpha: 1.0)
	}

	deinit {
		for notificationName in [UIKeyboardWillShowNotification, UIKeyboardWillHideNotification] {
			NSNotificationCenter.defaultCenter().removeObserver(self, name: notificationName, object: nil)
		}
	}

	override func preferredStatusBarStyle() -> UIStatusBarStyle  {
		return .Default
	}

	override func loadView() {
		view = UIView(frame: UIScreen.mainScreen().applicationFrame)
		view.addSubview(suggestionsTableView)
	}

	override func viewDidLoad() {
		super.viewDidLoad()

		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
		NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)

		navigationController.navigationBar.barTintColor = UIColor(red: (220.0 / 255.0), green: (223.0 / 255.0), blue: (226.0 / 255.0), alpha:1.0)
		navigationItem.titleView = wordSearchBar
		navigationItem.titleView.autoresizingMask = .FlexibleWidth

		suggestionsTableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
		suggestionsTableView.tableFooterView = UIView(frame: CGRectZero)

		wordSearchBar.sizeToFit()
	}

	override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		suggestionsTableView.deselectRowAtIndexPath(suggestionsTableView.indexPathForSelectedRow(), animated: false)
		wordSearchBar.becomeFirstResponder()
	}

	override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval)  {
		suggestionsTableView.reloadData()
	}

	func searchBar(searchBar: UISearchBar!, textDidChange searchText: NSString) {
		showingSuggestions = !searchBar.text.isEmpty

		if showingSuggestions {
			var availableLanguages = UITextChecker.availableLanguages() as String[]
			words = textChecker.completionsForPartialWordRange(NSMakeRange(0, searchBar.text.utf16count), inString: searchBar.text, language: availableLanguages[0]) as String[]
			words = words.filter {
				return !($0.hasSuffix("'") || $0.hasSuffix("'s")  || $0.hasSuffix("."))
			}
			wordSearchBar.tintColor = UIColor(red: 0.0, green: (118.0 / 255.0), blue: 1.0, alpha: 1.0)
		} else {
			words = viewedWords.copy()
			wordSearchBar.tintColor = UIColor(red: (194.0 / 255.0), green: (197.0 / 255.0), blue: (200.0 / 255.0), alpha: 1.0)
		}

		suggestionsTableView.reloadData()
	}

	func searchBarSearchButtonClicked(searchBar: UISearchBar!) {
		referenceLibraryViewController = UIReferenceLibraryViewController(term: words[0])
		self.tableView(suggestionsTableView, didSelectRowAtIndexPath: NSIndexPath(forRow: 0, inSection: 0))
	}

	func tableView(tableView: UITableView!, numberOfRowsInSection section: Int) -> Int {
		return words.count
	}

	func tableView(tableView: UITableView!, cellForRowAtIndexPath indexPath: NSIndexPath!) -> UITableViewCell! {
		var cell = tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell
		cell.textLabel.text = words[indexPath.row]

		return cell
	}

	func tableView(tableView: UITableView!, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath! {
		referenceLibraryViewController = UIReferenceLibraryViewController(term: words[indexPath.row])
		return indexPath
	}

	func tableView(tableView: UITableView!, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		var term = words[indexPath.row];

		viewedWords = viewedWords.filter {
			return $0 != term
		}
		viewedWords.insert(term, atIndex: 0)

		while viewedWords.count > 25 {
			viewedWords.removeLast()
		}

		self.presentViewController(referenceLibraryViewController!, animated: true, completion: nil)
	}

	func tableView(tableView: UITableView!, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
		return !showingSuggestions
	}

	func tableView(tableView: UITableView!, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
		words.removeAtIndex(indexPath.row)

		tableView.beginUpdates()
		tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
		tableView.endUpdates()
	}

	func keyboardWillShow(notification: NSNotification) {
		var keyboardFrame = notification.userInfo[UIKeyboardFrameEndUserInfoKey].CGRectValue()
		suggestionsTableView.contentInset = UIEdgeInsetsMake(64.0, 0.0, keyboardFrame.size.height, 0.0)
	}

	func keyboardWillHide(notification: NSNotification) {
		suggestionsTableView.contentInset = UIEdgeInsetsMake(64.0, 0.0, 0.0, 0.0)
	}
}
