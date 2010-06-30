#import <Preferences/Preferences.h>
#import <QuartzCore/QuartzCore.h>

#import "libactivator.h"
#import "libactivator-private.h"
#import "ActivatorAdController.h"

// TODO: figure out the proper way to store this in headers
@interface PSViewController (OS32)
@property (nonatomic, retain) PSSpecifier *specifier;
@end

@interface ActivatorPSViewControllerHost : PSViewController<LASettingsViewControllerDelegate> {
@private
	LASettingsViewController *_settingsController;
}
- (id)initForContentSize:(CGSize)size;
@property (nonatomic, retain) LASettingsViewController *settingsController;
- (void)loadFromSpecifier:(PSSpecifier *)specifier;
@end

@implementation ActivatorPSViewControllerHost

- (id)initForContentSize:(CGSize)size
{
	if ([[PSViewController class] instancesRespondToSelector:@selector(initForContentSize:)])
		return [super initForContentSize:size];
	else
		return [super init];
}

- (void)dealloc
{
	_settingsController.delegate = nil;
	[_settingsController release];
	[super dealloc];
}

- (LASettingsViewController *)settingsController
{
	return _settingsController;
}

- (void)setSettingsController:(LASettingsViewController *)settingsController
{
	if (_settingsController != settingsController) {
		_settingsController.delegate = nil;
		[_settingsController release];
		_settingsController = [settingsController retain];
		_settingsController.delegate = self;
	}
}

- (NSString *)navigationTitle
{
	return _settingsController.navigationItem.title;
}

- (UINavigationItem *)navigationItem
{
	return _settingsController.navigationItem;
}

- (void)setSpecifier:(PSSpecifier *)specifier
{
	[self loadFromSpecifier:specifier];
	[super setSpecifier:specifier];
}

- (void)viewWillBecomeVisible:(void *)source
{
	if (source)
		[self loadFromSpecifier:(PSSpecifier *)source];
	[super viewWillBecomeVisible:source];
}

- (void)loadFromSpecifier:(PSSpecifier *)specifier
{
}

- (UIView *)view
{
	return _settingsController.view;
}

- (void)settingsViewController:(LASettingsViewController *)settingsController shouldPushToChildController:(LASettingsViewController *)childController
{
	ActivatorPSViewControllerHost *vch = [[ActivatorPSViewControllerHost alloc] initForContentSize:_settingsController.view.frame.size];
	vch.settingsController = childController;
	[self pushController:vch];
	[vch setParentController:self];
	[vch release];
}

@end

@interface ActivatorSettingsController : ActivatorPSViewControllerHost {
@private
	BOOL shouldShowAds;
}
@end

@implementation ActivatorSettingsController

- (void)loadFromSpecifier:(PSSpecifier *)specifier
{
	// Load LAListenerSettingsViewController if activatorListener is set in the specifier
	LASettingsViewController *sc;
	NSString *listenerName = [specifier propertyForKey:@"activatorListener"];
	if ([listenerName length]) {
		NSLog(@"libactivator: Configuring %@", listenerName);
		LAListenerSettingsViewController *lsvc = [LAListenerSettingsViewController controller];
		sc = lsvc;
		lsvc.listenerName = listenerName;
		NSString *title = [[specifier propertyForKey:@"activatorTitle"]?:[specifier name] copy];
		if ([title length])
			lsvc.navigationItem.title = title;
		shouldShowAds = NO;
	} else {
		sc = [LARootSettingsController controller];
		shouldShowAds = ![[LASharedActivator _getObjectForPreference:@"LAHideAds"] boolValue];
	}
	self.settingsController = sc;
}

- (void)viewDidBecomeVisible
{
	[super viewDidBecomeVisible];
	if (shouldShowAds) {
		ActivatorAdController *aac = [ActivatorAdController sharedInstance];
		[aac setURL:[LASharedActivator moreActionsURL]];
		[aac displayOnTarget:[[self view] superview]];
	}
}

- (BOOL)popControllerWithAnimation:(BOOL)animation
{
	[[ActivatorAdController sharedInstance] hideAnimated:YES];
	return [super popControllerWithAnimation:animation];
}

@end

__attribute__((constructor))
static void Init() {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"Activator: Loaded in settings");
	[pool release];
}
