//
//  main.c
//  TodoApp
//
//  Created by Alex Usbergo on 5/8/17.
//  Copyright © 2017 Alex Usbergo. All rights reserved.
//

#include <stdio.h>

// Remote Plugin patch start //

#ifdef DEBUG
#define REMOTE_PORT 31459
#include "/Applications/Injection.app/Contents/Resources/RemoteCapture.h"
#define REMOTEPLUGIN_SERVERIPS "100.104.189.200"
@implementation RemoteCapture(Startup)
+ (void)load {
    [self performSelectorInBackground:@selector(startCapture:) withObject:@REMOTEPLUGIN_SERVERIPS];
}
@end
#endif

// Remote Plugin patch end //
