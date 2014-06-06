#import "LXViewController.h"

@interface LXViewController () <UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>
@end

@implementation LXViewController {
	UISearchBar *_wordSearchBar;
	UITableView *_suggestionsTableView;
	UITextChecker *_textChecker;

	UIReferenceLibraryViewController *_referenceLibraryViewController;

	BOOL _showingSuggestions;
	NSMutableArray *_items;
	NSMutableArray *_savedItems;
}

- (id) init {
	if (!(self = [super init]))
		return nil;

	_textChecker = [[UITextChecker alloc] init];
	_wordSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0., CGRectGetMaxY([UIApplication sharedApplication].statusBarFrame), 0., 44.)];
	_wordSearchBar.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin);
	_wordSearchBar.delegate = self;
	_wordSearchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	_wordSearchBar.tintColor = [UIColor colorWithRed:(194. / 255.) green:(197. / 255.) blue:(200. / 255.) alpha:1.];

	_suggestionsTableView = [[UITableView alloc] initWithFrame:CGRectMake(0., 0., 0., 0.) style:UITableViewStylePlain];
	_suggestionsTableView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin);
	_suggestionsTableView.dataSource = self;
	_suggestionsTableView.delegate = self;

	_savedItems = [NSMutableArray array];

	return self;
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleDefault;
}

- (void) loadView {
	UIView *view = [[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame];
	[view addSubview:_suggestionsTableView];

	self.view = view;
}

- (void) viewDidLoad {
	[super viewDidLoad];

	self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:(220. / 255.) green:(223. / 255.) blue:(226. / 255.) alpha:1.];
	self.navigationItem.titleView = _wordSearchBar;
	self.navigationItem.titleView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];

	_suggestionsTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
	[_suggestionsTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];

	[_wordSearchBar sizeToFit];
}

- (void) viewWillAppear:(BOOL) animated {
	[super viewWillAppear:animated];

	[_suggestionsTableView deselectRowAtIndexPath:_suggestionsTableView.indexPathForSelectedRow animated:NO];

	[_wordSearchBar becomeFirstResponder];
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation) toInterfaceOrientation duration:(NSTimeInterval) duration {
	// reload to force the tableview to redraw; iOS 7 bug where the tableviewcell line doesn't update and stays at half-width on rotation to landscape
	[_suggestionsTableView reloadData];
}

- (void) keyboardWillShow:(NSNotification *) notification {
	CGRect keyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];

	_suggestionsTableView.contentInset = UIEdgeInsetsMake(64., 0., keyboardFrame.size.height, 0.);
}

- (void) keyboardWillHide:(NSNotification *) notification {
	_suggestionsTableView.contentInset = UIEdgeInsetsMake(64., 0., 0., 0.);
}

- (void) searchBar:(UISearchBar *) searchBar textDidChange:(NSString *) searchText {
	if (searchBar.text.length) {
		NSArray *items = [_textChecker completionsForPartialWordRange:NSMakeRange(0, searchBar.text.length) inString:searchBar.text language:[UITextChecker availableLanguages][0]];
		NSMutableArray *workingItems = [items mutableCopy];
		for (NSString *word in items) // trim out 's (eg: bat's)
			if ([word characterAtIndex:(word.length - 1)] == '\'' || [word characterAtIndex:(word.length - 2)] == '\'')
				[workingItems removeObject:word];

		_items = workingItems;
		_showingSuggestions = YES;
		_wordSearchBar.tintColor = [UIColor colorWithRed:(0. / 255.) green:(118. / 255.) blue:(255. / 255.) alpha:1.];
	} else {
		_items = [_savedItems mutableCopy];
		_showingSuggestions = NO;
		_wordSearchBar.tintColor = [UIColor colorWithRed:(194. / 255.) green:(197. / 255.) blue:(200. / 255.) alpha:1.];

	}

	[_suggestionsTableView reloadData];
}

- (void) searchBarSearchButtonClicked:(UISearchBar *) searchBar {
	_referenceLibraryViewController = [[UIReferenceLibraryViewController alloc] initWithTerm:_items[0]];

	[self tableView:_suggestionsTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (NSInteger) tableView:(UITableView *) tableView numberOfRowsInSection:(NSInteger) section {
	return _items.count;
}

- (UITableViewCell *) tableView:(UITableView *) tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
	cell.textLabel.text = _items[indexPath.row];

	return cell;
}

- (NSIndexPath *) tableView:(UITableView *) tableView willSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	_referenceLibraryViewController = [[UIReferenceLibraryViewController alloc] initWithTerm:_items[indexPath.row]];

	return indexPath;
}

- (void) tableView:(UITableView *) tableView didSelectRowAtIndexPath:(NSIndexPath *) indexPath {
	NSString *term = _items[indexPath.row];

	NSUInteger index = [_savedItems indexOfObject:term];
	if (index != NSNotFound)
		[_savedItems removeObjectAtIndex:index];
	[_savedItems insertObject:term atIndex:0];

	while (_savedItems.count > 25)
		[_savedItems removeLastObject];

	[self presentViewController:_referenceLibraryViewController animated:YES completion:NULL];
}

- (BOOL) tableView:(UITableView *) tableView canEditRowAtIndexPath:(NSIndexPath *) indexPath {
	return !_showingSuggestions;
}

- (void) tableView:(UITableView *) tableView commitEditingStyle:(UITableViewCellEditingStyle) editingStyle forRowAtIndexPath:(NSIndexPath *) indexPath {
	[_items removeObjectAtIndex:indexPath.row];

	[tableView beginUpdates];
	[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
	[tableView endUpdates];
}
@end
