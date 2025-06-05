#import "FuseObjcBridger.h"
#import <Foundation/Foundation.h>

// Constructor function that runs before main()
__attribute__((constructor))
static void runAutoRegister(void) {
    NSLog(@"Constructor runAutoRegister called - calling Swift factory registration");
    // Direct call to Swift function
    fuseRegisterFactory();
}
