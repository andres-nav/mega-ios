#import <UIKit/UIKit.h>

@interface OpenAppRequiredViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButtonItem;
@property (nonatomic, copy) void (^cancelCompletion)(void);

@end
