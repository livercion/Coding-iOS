//
//  NewProjectViewController.m
//  Coding_iOS
//
//  Created by isaced on 15/3/30.
//  Copyright (c) 2015年 Coding. All rights reserved.
//

#import "NewProjectViewController.h"
#import "NewProjectTypeViewController.h"
#import "Coding_NetAPIManager.h"
#import "UIImageView+WebCache.h"

@interface NewProjectViewController ()<NewProjectTypeDelegate,UITextFieldDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@property (nonatomic, assign) NewProjectType projectType;
@property (nonatomic, strong) UIBarButtonItem *submitButtonItem;
@property (nonatomic, strong) UIImage *projectIconImage;

@end

@implementation NewProjectViewController

-(void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //
    for (NSLayoutConstraint *cons in self.lines) {
        cons.constant = 0.5;
    }
    
    //
    self.tableView.tableFooterView = [UIView new];
    [self.tableView setSeparatorColor:[UIColor colorWithRGBHex:0xe5e5e5]];
    
    //
    self.descTextView.placeholder = @"填写项目描述...";

    //
    self.projectImageView.layer.cornerRadius = 5;
    self.projectImageView.image = [UIImage imageNamed:@"AppIcon120x120"];
    UITapGestureRecognizer *tapProjectImageViewGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectProjectImage)];
    [self.projectImageView addGestureRecognizer:tapProjectImageViewGR];
    
    // 添加 “完成” 按钮
    self.submitButtonItem = [UIBarButtonItem itemWithBtnTitle:@"完成" target:self action:@selector(submit)];
    self.submitButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem = self.submitButtonItem;
    
    // 默认类型
    self.projectType = NewProjectTypePrivate;

    static NSString *projectIconURLString = @"https://coding.net/static/project_icon/scenery-%d.png";
    int x = arc4random() % 24 + 1;
    NSString *randomIconURLString = [NSString stringWithFormat:projectIconURLString,x];
    [self.projectImageView sd_setImageWithURL:[NSURL URLWithString:randomIconURLString] placeholderImage:[UIImage imageNamed:@"AppIcon120x120"] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image) {
            self.projectIconImage = image;
        }
    }];
}

-(void)selectProjectImage{
    [[UIActionSheet bk_actionSheetCustomWithTitle:@"选择照片" buttonTitles:@[@"拍照",@"从相册选择"] destructiveTitle:nil cancelTitle:@"取消" andDidDismissBlock:^(UIActionSheet *sheet, NSInteger index) {
        
        if (index > 1) {
            return ;
        }
        
        UIImagePickerController *avatarPicker = [[UIImagePickerController alloc] init];
        avatarPicker.delegate = self;
        if (index == 0) {
            avatarPicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        }else{
            avatarPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        }
        avatarPicker.allowsEditing = YES;
        [self presentViewController:avatarPicker animated:YES completion:nil];
    }] showInView:self.view];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    
    if (image) {
        self.projectImageView.image = image;
        self.projectIconImage = image;
    }

    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)submit{

    NSString *projectName = [self.projectNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if ([projectName length] < 2 || [projectName length] > 31) {
        [[[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入2 ~ 31位以内的项目名称" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles: nil] show];
    }else{
        if ([self projectNameVerification:projectName]) {
            
            // init a Project
            Project *project = [[Project alloc] init];
            project.name = projectName;
            project.description_mine = [self.descTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            
            if (self.projectType == NewProjectTypePublic) {
                project.is_public = @YES;
            }else{
                project.is_public = @NO;
            }
            
            self.submitButtonItem.enabled = NO;
            
            // 效验完成，开始发送请求创建项目
            [[Coding_NetAPIManager sharedManager] request_NewProject_WithObj:project image:self.projectIconImage andBlock:^(Project *data, NSError *error) {
                if (!error) {
                    [self.navigationController popToRootViewControllerAnimated:YES];
                }
                self.submitButtonItem.enabled = YES;
            }];
        }else{
            [[[UIAlertView alloc] initWithTitle:@"提示" message:@"项目名只允许字母、数字或者下划线(_)、中划线(-)，必须以字母或者数字开头,且不能以.git结尾" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles: nil] show];
        }
    }

}

-(BOOL)projectNameVerification:(NSString *)projectName{
    NSString * regex = @"^[a-zA-Z0-9][a-zA-Z0-9_-]+$";
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
    BOOL isMatch = [pred evaluateWithObject:projectName];
    return isMatch;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string{
    NSString *str = [textField.text stringByReplacingCharactersInRange:range withString:string];
    
    if ([str length] > 0) {
        self.submitButtonItem.enabled = YES;
    }else{
        self.submitButtonItem.enabled = NO;
    }
    
    return YES;
}

#pragma mark UITableView

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    return [UIView new];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == 1 && indexPath.row == 0) {
        // 类型
        NewProjectTypeViewController *vc = [self.storyboard instantiateViewControllerWithIdentifier:@"NewProjectTypeVC"];
        vc.projectType = self.projectType;
        vc.delegate = self;
        [self.navigationController pushViewController:vc animated:YES];
    }
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    //
    if (indexPath.section == 0 && indexPath.row == 0) {
        return;
    }
    if (indexPath.section == 1 && indexPath.row == 0) {
         cell.separatorInset = UIEdgeInsetsMake(0.f, cell.bounds.size.width, 0.f, 0.f);
        return;
    }
    
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }

}

#pragma mark NewProjectTypeViewController Delegate

-(void)newProjectType:(NewProjectTypeViewController *)newProjectVC didSelectType:(NewProjectType)type{
    [newProjectVC.navigationController popViewControllerAnimated:YES];
    
    //
    self.projectType = type;
    
    if (self.projectType == NewProjectTypePublic) {
        self.projectTypeLabel.text = @"公开";
    }else{
        self.projectTypeLabel.text = @"私有";
    }
}

@end