//
//  CNCAppDelegate.m
//  CustomNCUI
//
//  Created by inket on 28/07/2012.
//  Copyright (c) 2012-2013 inket. Licensed under GNU GPL v3.0. See LICENSE for details.
//

#import "CNCAppDelegate.h"

#define RUNNING_AGENT ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.github.norio-nomura.SIMBL-Agent"])
#define RUNNING_NC ([NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.notificationcenterui"])

@implementation CNCAppDelegate

@synthesize window;

@synthesize alwaysPulseIcon;
@synthesize hideIcon;

@synthesize entryAnimationStyle;
@synthesize entryAnimationDuration;

@synthesize bannerIdleDuration;

@synthesize exitAnimationStyle;
@synthesize exitAnimationDuration;

@synthesize fixGrowl;
@synthesize removeAppName;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
}

- (IBAction)changeGrowlCheckboxValue:(id)sender {
    [removeAppName setEnabled:[fixGrowl state]];
    if (![removeAppName isEnabled]) [removeAppName setState:NSOffState];
}

- (IBAction)changeSliderValue:(id)sender {
    [[sender valueLabel] setStringValue:[sender formatString]];
}

- (IBAction)changeExitAnimationStyle:(id)sender {
    if ([(NSPopUpButton*)sender indexOfSelectedItem] == 2)
    {
        [exitAnimationDuration setEnabled:NO];
        [exitAnimationDuration setDoubleValue:0.25];
    }
    else
        [exitAnimationDuration setEnabled:YES];
}

- (IBAction)apply:(id)sender {
    if (DEBUG_ENABLED) NSLog(@"%@ user clicked Apply", isEasySIMBL?@"EasySIMBL":@"SIMBL");
    
    [sender setTarget:nil];
    [sender setAction:nil];
    [_progressIndicator setHidden:NO];
    [_progressIndicator setDoubleValue:0];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];

    [userDefaults setBool:[alwaysPulseIcon state] forKey:@"alwaysPulseIcon"];
    [userDefaults setBool:[hideIcon state] forKey:@"hideIcon"];

    [userDefaults setInteger:[entryAnimationStyle indexOfSelectedItem] forKey:@"entryAnimationStyle"];
    [userDefaults setDouble:[[entryAnimationDuration stringValue] doubleValue] forKey:@"entryAnimationDuration"];
    
    [userDefaults setInteger:[exitAnimationStyle indexOfSelectedItem] forKey:@"exitAnimationStyle"];
    [userDefaults setDouble:[[exitAnimationDuration stringValue] doubleValue] forKey:@"exitAnimationDuration"];
    
    [userDefaults setDouble:[[bannerIdleDuration stringValue] doubleValue] forKey:@"bannerIdleDuration"];
    
    [userDefaults setBool:[fixGrowl state] forKey:@"fixGrowl"];
    [userDefaults setBool:[removeAppName state] forKey:@"removeAppName"];
    
    [userDefaults synchronize];
    
    [_progressIndicator incrementBy:10];
    
    NSArray* runningNC = RUNNING_NC;
    
    if ([runningNC count] > 0)
    {
        [(NSRunningApplication*)runningNC[0] terminate];
        if (DEBUG_ENABLED) NSLog(@"Killed NC");
        [_progressIndicator incrementBy:10];

        double slept = 0;
        
        while ([RUNNING_NC count] == 0 && slept < 5)
        {
            sleep(1);
            slept += 1;
        }
        
        if ([RUNNING_NC count] == 0)
        {
            NSAlert* alert = [NSAlert alertWithMessageText:@"Uh oh. There seems to be a problem." defaultButton:@"Try later" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"Notification Center is not running. Please restart and try again."];
            
            [alert runModal];
            
            [NSApp terminate:self];
        }
        else
        {
            [_progressIndicator incrementBy:30];
            [self performSelector:@selector(inject) withObject:nil afterDelay:2];
        }
    }
    
}

- (void)inject {    
    if (isEasySIMBL)
        [self easySIMBLInject];
    else if (isSIMBL)
        [self SIMBLInject];
    
    [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(activate) userInfo:nil repeats:NO];
}

- (void)easySIMBLInject {
    if (DEBUG_ENABLED) NSLog(@"User has EasySIMBL, trying to kill the agent");
    
    NSArray* runningAgent = RUNNING_AGENT;
    
    if ([runningAgent count] > 0)
    {
        NSString* agentPath = [[[(NSRunningApplication*)runningAgent[0] bundleURL] path] copy];
        [(NSRunningApplication*)runningAgent[0] terminate];
        
        if (DEBUG_ENABLED) NSLog(@"Killed the agent @ %@", agentPath);
        [_progressIndicator incrementBy:30];
        
        int slept = 0;
        
        while ([RUNNING_AGENT count] > 0 && slept < 5)
        {
            sleep(1);
            slept += 1;
        }
        
        if ([RUNNING_AGENT count] == 0)
        {
            [[NSWorkspace sharedWorkspace] openFile:agentPath];
            if (DEBUG_ENABLED) NSLog(@"Started the agent");
            [_progressIndicator incrementBy:20];
        }
    }
    else
    {
        NSAlert* alert = [NSAlert alertWithMessageText:@"Uh oh. There seems to be a problem." defaultButton:@"Try later" alternateButton:@"" otherButton:@"" informativeTextWithFormat:@"EasySIMBL's agent is not running. You'll have to restart for the changes to be effective."];
        
        [alert runModal];
    }
}

- (void)SIMBLInject {
    if (DEBUG_ENABLED) NSLog(@"User has SIMBL, trying to start the injector");
    
    NSString* launcherPath = [[NSBundle mainBundle] pathForResource:@"CustomNCLauncher" ofType:@"app"];
    
    [[NSWorkspace sharedWorkspace] openFile:launcherPath];
    
    [_progressIndicator incrementBy:50];
    if (DEBUG_ENABLED) NSLog(@"Told SIMBL to inject CustomNC");
}

- (void)install {
    NSFileManager* fileManager = [NSFileManager defaultManager];
    
    // *** Making sure SIMBL is installed
    BOOL isDir = NO;
    NSString* SIMBLpath = @"/Library/ScriptingAdditions/SIMBL.osax";
    NSString* SIMBLuserPath = [@"~/Library/ScriptingAdditions/SIMBL.osax" stringByExpandingTildeInPath];
    NSString* easySIMBLpath = [@"~/Library/ScriptingAdditions/EasySIMBL.osax" stringByExpandingTildeInPath];

    isSIMBL = [fileManager fileExistsAtPath:SIMBLpath isDirectory:&isDir] || [fileManager fileExistsAtPath:SIMBLuserPath isDirectory:&isDir];
    isEasySIMBL = [fileManager fileExistsAtPath:easySIMBLpath isDirectory:&isDir] || [RUNNING_AGENT count] > 0;
    
    if (DEBUG_ENABLED) NSLog(@"SIMBL: %@, EasySIMBL: %@", isSIMBL?@"YES":@"NO", isEasySIMBL?@"YES":@"NO");

    if (!isSIMBL && !isEasySIMBL)
    {
        NSAlert* alert = [NSAlert alertWithMessageText:@"CustomNC requires SIMBL to function" defaultButton:@"Take me there!" alternateButton:@"Cancel" otherButton:@"" informativeTextWithFormat:@"SIMBL is a transparent app that enables modifications like CustomNC. It's easy to install and doesn't need any setup.\n\nGet it on http://www.culater.net/software/SIMBL/SIMBL.php"];
        
        NSInteger buttonClicked = [alert runModal];
        
        if (buttonClicked == 1)
            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://www.culater.net/software/SIMBL/SIMBL.php"]];
        
        [NSApp terminate:self];
    }
    
    // *** Making sure the plugin is in place
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    
    NSString* pluginPath = [NSBundle pathForResource:@"CustomNC" ofType:@"bundle" inDirectory:resourcePath];
    double newPluginVersion = [[[[NSBundle bundleWithPath:pluginPath] infoDictionary] objectForKey:@"CFBundleShortVersionString"] doubleValue];
    
    NSString* pluginsDirectory = [@"~/Library/Application Support/SIMBL/Plugins/" stringByExpandingTildeInPath];
    NSString* destination = [NSString stringWithFormat:@"%@/CustomNC.bundle", pluginsDirectory];
    BOOL isDirectory = NO;
    
    NSBundle* bundle = [NSBundle bundleWithPath:destination];
    double pluginVersion = [[[bundle infoDictionary] objectForKey:@"CFBundleShortVersionString"] doubleValue];
    
    if (!bundle)
    {
        NSError* error = nil;
        
        [fileManager createDirectoryAtPath:pluginsDirectory withIntermediateDirectories:YES attributes:nil error:&error];
        
        if (![fileManager fileExistsAtPath:pluginsDirectory isDirectory:&isDirectory])
        {
            [[NSAlert alertWithError:error] runModal];
            NSLog(@"Couldn't find/create plugins directory @ %@", pluginsDirectory);
            [NSApp terminate:self];
        }
        
        error = nil;
        [fileManager copyItemAtPath:pluginPath toPath:destination error:&error];
        
        if (error)
        {
            [[NSAlert alertWithError:error] runModal];
            NSLog(@"Couldn't install CustomNC SIMBL plugin. Quitting...");
            [NSApp terminate:self];
        }
    }
    else if (newPluginVersion != pluginVersion)
    {
        NSError* error = nil;
        [fileManager removeItemAtPath:destination error:&error];
        
        if (error)
        {
            [[NSAlert alertWithError:error] runModal];
            NSLog(@"Couldn't replace CustomNC plugin @ %@ with a newer version", destination);
            [NSApp terminate:self];
        }
        
        error = nil;
        [fileManager copyItemAtPath:pluginPath toPath:destination error:&error];
        
        if (error)
        {
            [[NSAlert alertWithError:error] runModal];
            NSLog(@"Couldn't install CustomNC SIMBL plugin. Quitting...");
            [NSApp terminate:self];
        }
        
        NSLog(@"Replaced CustomNC plugin with a newer version successfully.");
    }
}

- (IBAction)defaults:(id)sender {
    [alwaysPulseIcon setState:NSOffState];
    [hideIcon setState:NSOffState];
    
    [entryAnimationStyle selectItemAtIndex:0];
    [entryAnimationDuration setDoubleValue:0.7];
    
    [bannerIdleDuration setDoubleValue:5];
    
    [exitAnimationStyle selectItemAtIndex:0];
    [exitAnimationDuration setEnabled:YES];
    [exitAnimationDuration setDoubleValue:0.6];
    
    [fixGrowl setState:NSOffState];
    [self changeGrowlCheckboxValue:fixGrowl];
    
    [removeAppName setState:NSOffState];
}

- (IBAction)uninstall:(id)sender {
    NSFileManager* fileManager = [NSFileManager defaultManager];

    NSString* pluginsDirectory = [@"~/Library/Application Support/SIMBL/Plugins/" stringByExpandingTildeInPath];
    NSString* destination = [NSString stringWithFormat:@"%@/CustomNC.bundle", pluginsDirectory];
    
    NSError* error = nil;
    [fileManager removeItemAtPath:destination error:&error];
    
    if (error)
        [NSAlert alertWithError:error];

    [self removeLoginItem];
    
    NSArray* runningNC = RUNNING_NC;
    
    if ([runningNC count] > 0)
        [(NSRunningApplication*)runningNC[0] terminate];
    
    [fileManager trashItemAtURL:[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", [[NSBundle mainBundle] bundlePath]]] resultingItemURL:nil error:&error];
    
    [NSApp terminate:self];
}

- (void)addLoginItem {
    if (![LoginItem loginItemExists])
        [LoginItem addLoginItem];
}

- (void)removeLoginItem {
    if ([LoginItem loginItemExists])
        [LoginItem removeLoginItem];
}

- (IBAction)sendNotification:(id)sender {
    NSUserNotification* notification = [[NSUserNotification alloc] init];
    [notification setTitle:@"Test notification"];
    [notification setSubtitle:@"Lorem Ipsum Dolor Sit Amet, Consectetur Adipiscing Elit"];
    
    NSString* informativeText = [NSString stringWithFormat:@"It's %@ now!", [[NSDate date] descriptionWithLocale:[NSLocale currentLocale]]];
    [notification setInformativeText:informativeText];
    
    if ([RUNNING_NC count] > 0)
    {
        [[RUNNING_NC objectAtIndex:0]  activateWithOptions:NSApplicationActivateAllWindows];
        
        [self performSelector:@selector(notify:) withObject:notification afterDelay:0.3];
    }
}

- (void)notify:(NSUserNotification*)notification {
    NSUserNotificationCenter* notificationCenter = [NSUserNotificationCenter defaultUserNotificationCenter];
    [notificationCenter deliverNotification:notification];
    [self performSelector:@selector(activate) withObject:nil afterDelay:0.3];
}

- (IBAction)sendGrowlNotification:(id)sender {
    NSString* asSource = @"\
    tell application \"System Events\"\n\
    set isRunning to (count of (every process whose bundle identifier is \"com.Growl.GrowlHelperApp\")) > 0\n\
    end tell\n\
    \n\
    if isRunning then\n\
        tell application id \"com.Growl.GrowlHelperApp\"\n\
            set the allNotificationsList to ¬\n\
                {\"Test Notification\"}\n\
            \n\
            set the enabledNotificationsList to ¬\n\
                {\"Test Notification\"}\n\
            \n\
            \n\
            register as application ¬\n\
                \"CustomNC\" all notifications allNotificationsList ¬\n\
                default notifications enabledNotificationsList ¬\n\
                icon of application \"CustomNC\"\n\
            \n\
            \n\
            notify with name ¬\n\
                \"Test Notification\" title ¬\n\
                \"Test Notification\" description ¬\n\
                \"Lorem Ipsum Dolor Sit Amet, Consectetur Adipiscing Elit.\" application name \"CustomNC\"\n\
            \n\
        end tell\n\
    end if";
    
    NSAppleScript* as = [[NSAppleScript alloc] initWithSource:asSource];
    
    NSDictionary* error = nil;
    [as executeAndReturnError:&error];
    
    if (error)
        NSLog(@"%@", error);
}

- (void)activate {
    [(NSApplication*)NSApp activateIgnoringOtherApps:YES];
    [_progressIndicator setHidden:YES];
    [_applyButton setTarget:self];
    [_applyButton setAction:@selector(apply:)];
}

- (void)awakeFromNib {
    [entryAnimationDuration setAltIncrementValue:0.5];
    [entryAnimationDuration setFormatString:@"%@ second%@"];
    [bannerIdleDuration setAltIncrementValue:0.5];
    [bannerIdleDuration setFormatString:@"approx. %@ second%@"];
    [exitAnimationDuration setAltIncrementValue:0.5];
    [exitAnimationDuration setFormatString:@"%@ second%@"];
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self install];
    
    if (!isEasySIMBL)
        // SIMBL doesn't inject apps at user login
        // so we have to do that with an automator workflow set as a login item
        [self addLoginItem];
    else
        // EasySIMBL doesn't have such problems
        [self removeLoginItem];
    
    NSNumber* entryDuration = [userDefaults objectForKey:@"entryAnimationDuration"];
    [entryAnimationDuration setMaxDigits:4];
    [entryAnimationDuration setDoubleValue:entryDuration?[entryDuration doubleValue]:0.7];
    NSNumber* entryStyle = [userDefaults objectForKey:@"entryAnimationStyle"];
    [entryAnimationStyle selectItemAtIndex:entryStyle?[entryStyle integerValue]:0];
    
    NSNumber* idleDuration = [userDefaults objectForKey:@"bannerIdleDuration"];
    [bannerIdleDuration setMaxDigits:3];
    [bannerIdleDuration setDoubleValue:idleDuration?[idleDuration doubleValue]:5];
    
    NSNumber* exitDuration = [userDefaults objectForKey:@"exitAnimationDuration"];
    [exitAnimationDuration setMaxDigits:4];
    [exitAnimationDuration setDoubleValue:exitDuration?[exitDuration doubleValue]:0.6];
    NSNumber* exitStyle = [userDefaults objectForKey:@"exitAnimationStyle"];
    [exitAnimationStyle selectItemAtIndex:exitStyle?[exitStyle integerValue]:0];
    if ([exitAnimationStyle indexOfSelectedItem] == 2)
        [exitAnimationDuration setEnabled:NO];
    
    BOOL alwaysPulse = [userDefaults objectForKey:@"alwaysPulseIcon"]?[[userDefaults objectForKey:@"alwaysPulseIcon"] boolValue]:NO;
    [alwaysPulseIcon setState:alwaysPulse?NSOnState:NSOffState];
    
    BOOL hide = [userDefaults objectForKey:@"hideIcon"]?[[userDefaults objectForKey:@"hideIcon"] boolValue]:NO;
    [hideIcon setState:hide?NSOnState:NSOffState];
    
    BOOL fixGrowlVal = [userDefaults objectForKey:@"fixGrowl"]?[[userDefaults objectForKey:@"fixGrowl"] boolValue]:NO;
    [fixGrowl setState:fixGrowlVal?NSOnState:NSOffState];
    [self changeGrowlCheckboxValue:fixGrowl];
    
    BOOL removeAppNameVal = [userDefaults objectForKey:@"removeAppName"]?[[userDefaults objectForKey:@"removeAppName"] boolValue]:NO;
    [removeAppName setState:removeAppNameVal?NSOnState:NSOffState];
}

@end
