#import "FuseObjcBridger.h"
#import <Foundation/Foundation.h>

// Constructor function that runs before main()
__attribute__((constructor))
static void runAutoRegister(void) {
    fuseRegisterFactory();
}
