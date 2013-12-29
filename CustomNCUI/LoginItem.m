#import "LoginItem.h"

@implementation LoginItem

+ (void)addLoginItem {
	NSString * appPath = [[NSBundle mainBundle] pathForResource:@"CustomNCLauncher" ofType:@"app"];
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	NSURL* url = [NSURL fileURLWithPath:appPath];
	
	// Create a reference to the shared file list.
	// We are adding it to the current user only.
	// If we want to add it all users, use
	// kLSSharedFileListGlobalLoginItems instead of
	//kLSSharedFileListSessionLoginItems
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
    
	if (loginItems) {
		//Insert an item to the list.
        NSDictionary *properties = [NSDictionary
                                    dictionaryWithObject:[NSNumber numberWithBool:YES]
                                    forKey:@"com.apple.loginitem.HideOnLaunch"];
        
		LSSharedFileListItemRef item = LSSharedFileListInsertItemURL(loginItems,
																	 kLSSharedFileListItemLast, NULL, NULL,
																	 (__bridge CFURLRef)url, (__bridge CFDictionaryRef)properties, NULL);
		if (item){
			CFRelease(item);
		}
	}
    
    if (loginItems) CFRelease(loginItems);
}

+ (void)removeLoginItem {
	NSString * appPath = [[NSBundle mainBundle] pathForResource:@"CustomNCLauncher" ofType:@"app"];
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	NSURL* url = [NSURL fileURLWithPath:appPath]; 
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
        
		for(int i=0 ; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
																		objectAtIndex:i];
			//Resolve the item with URL
            CFURLRef newUrl = (__bridge CFURLRef)url;
			if (LSSharedFileListItemResolve(itemRef, 0, &newUrl, NULL) == noErr) {
				NSString *urlPath = [(__bridge NSURL*)newUrl path];
				if ([urlPath isEqualToString:appPath]){
					LSSharedFileListItemRemove(loginItems, itemRef);
				}
			}

		}
    }
    
    if (loginItems) CFRelease(loginItems);
}

+ (BOOL)loginItemExists {
    BOOL found = NO;
	NSString * appPath = [[NSBundle mainBundle] pathForResource:@"CustomNCLauncher" ofType:@"app"];
	
	// This will retrieve the path for the application
	// For example, /Applications/test.app
	NSURL* url = [NSURL fileURLWithPath:appPath]; 
	
	// Create a reference to the shared file list.
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	
	if (loginItems) {
		UInt32 seedValue;
		//Retrieve the list of Login Items and cast them to
		// a NSArray so that it will be easier to iterate.
		NSArray  *loginItemsArray = (__bridge NSArray *)LSSharedFileListCopySnapshot(loginItems, &seedValue);
                
		for(int i=0 ; i< [loginItemsArray count]; i++){
			LSSharedFileListItemRef itemRef = (__bridge LSSharedFileListItemRef)[loginItemsArray
																		objectAtIndex:i];
			//Resolve the item with URL
            CFURLRef newUrl = (__bridge CFURLRef)url;
			if (LSSharedFileListItemResolve(itemRef, 0, &newUrl, NULL) == noErr) {
				NSString * urlPath = [(__bridge NSURL*)newUrl path];
				if ([urlPath isEqualToString:appPath]){
					found = YES;
				}
			}
		}
	}
    
    if (loginItems) CFRelease(loginItems);
    return found;
}

@end
