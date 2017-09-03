#import <Foundation/Foundation.h>

NSString *getUnNullString(NSString *inStr);

@interface BusinessBeanCopyUtil : NSObject

+ (id)cloneItem:(id)item;

@end
