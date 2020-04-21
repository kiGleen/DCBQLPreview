//
//  DCBQLPreviewController.m
//  DcbMain
//
//  Created by zoujing@gogpay.cn on 2020/4/8.
//  Copyright © 2020 cn.gogpay.dcb. All rights reserved.
//

#import "DCBQLPreviewController.h"
#import <QuickLook/QuickLook.h>

@interface DCBQLPreviewController ()<QLPreviewControllerDataSource>

@property (nonatomic, strong) QLPreviewController *previewController;
@property (nonatomic, copy) NSURL *fileURL;

@end

@implementation DCBQLPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UIBarButtonItem *barItem1 = [[UIBarButtonItem alloc] initWithTitle:@"本地文件" style:UIBarButtonItemStylePlain target:self action:@selector(loadLocalFileBtnAction)];
    UIBarButtonItem *barItem2 = [[UIBarButtonItem alloc] initWithTitle:@"网络文件" style:UIBarButtonItemStylePlain target:self action:@selector(loadNetFileBtnAction)];
    self.navigationItem.rightBarButtonItems = @[barItem1,barItem2];
    
    ///初始化
    self.previewController = [[QLPreviewController alloc]  init];
    self.previewController.dataSource  = self;

}


- (void)loadLocalFileBtnAction {
    [self loadLocalFile:@"QLPreviewFile.docx"];
}

- (void)loadNetFileBtnAction {
    NSString *urlStr = @"https://www.tutorialspoint.com/ios/ios_tutorial.pdf";
    [self loadNetFile:urlStr];
}



#pragma mark - QLPreviewControllerDataSource
-(id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return self.fileURL;
}
 
- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)previewController{
    return 1;
}



//获取本地文件路径
- (void)loadLocalFile:(NSString *)fileUrl {
    if (kStringIsEmpty(fileUrl)) return;

    NSString *path = [[NSBundle mainBundle] pathForResource:fileUrl ofType:nil];
    if (kStringIsEmpty(fileUrl)) {
        [MBProgressHUD showError:@"文件不存在"];
        return;
    }
    self.fileURL = [NSURL fileURLWithPath:path];
    [self presentViewController:self.previewController animated:YES completion:nil];
    //刷新界面,如果不刷新的话，不重新走一遍代理方法，返回的url还是上一次的url
    [self.previewController refreshCurrentPreviewItem];
}

//获取网络文件路径
- (void)loadNetFile:(NSString *)urlStr {
    if (kStringIsEmpty(urlStr)) return;
    [MBProgressHUD showMessage:@"下载中..."];
    [self loadNetFile:urlStr completed:^(NSURL *filePath) {
        [MBProgressHUD hideHUD];
        self.fileURL = filePath;
        [self presentViewController:self.previewController animated:YES completion:nil];
        //刷新界面,如果不刷新的话，不重新走一遍代理方法，返回的url还是上一次的url
        [self.previewController refreshCurrentPreviewItem];
    }];
}

//获取网络文件路径
- (void)loadNetFile:(NSString *)urlStr completed:(void(^)(NSURL *filePath))completed {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    
    //获取文件名称
    NSString *fileName = [urlStr lastPathComponent];
    NSURL *URL = [NSURL URLWithString:urlStr];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];

    //判断是否存在
    if([self isFileExist:fileName]) {
        NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
        NSURL *url = [documentsDirectoryURL URLByAppendingPathComponent:fileName];
        if (completed) {
            completed(url);
        }
    }else {
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:^(NSProgress *downloadProgress){
        } destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSURL *documentsDirectoryURL = [[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:NO error:nil];
            NSURL *url = [documentsDirectoryURL URLByAppendingPathComponent:fileName];
            return url;
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            if (completed) {
                completed(filePath);
            }
        }];
        [downloadTask resume];
    }
}


//判断文件是否已经在沙盒中存在
-(BOOL)isFileExist:(NSString *)fileName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *filePath = [path stringByAppendingPathComponent:fileName];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL result = [fileManager fileExistsAtPath:filePath];
    return result;
}


@end
