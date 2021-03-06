//
//  MainViewController.m
//  Luminous
//
//  Created by Erick Martin on 7/22/15.
//  Copyright (c) 2015 Erick Martin. All rights reserved.
//

#import "MainViewController.h"
#import "VariableModel.h"

@implementation MainViewController

@synthesize modelNameTextField, inputTextView, resultTextView, stateSegmented, resultArray;
@synthesize primaryKeyTextField;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

#pragma mark - IBAction
-(IBAction)changeState:(id)sender{
    [self generateTapped:nil];
}

-(IBAction)generateTapped:(id)sender{
    
    [self arrayOfVariableWithString:inputTextView.text];
    
    if(stateSegmented.selectedSegmentIndex == StateTypeModelHeader){
        resultTextView.text = [self createModelHeader];
    }else if(stateSegmented.selectedSegmentIndex == StateTypeModelMain){
        resultTextView.text = [self createModelMain];
    }else if(stateSegmented.selectedSegmentIndex == StateTypeDatabase){
        resultTextView.text = [self createDatabaseStringWithIdString:primaryKeyTextField.text];
    }
    
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setString:resultTextView.text];
    
}

-(NSArray *)arrayOfVariableWithString:(NSString *)inputStr{
    self.resultArray = [NSMutableArray array];

    NSMutableArray *data = [[inputStr componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]] mutableCopy];
    
    for(NSString *string in data){
        VariableModel *varModel = [[VariableModel alloc] initWithString:string];
        [resultArray addObject:varModel];
    }
    return resultArray;
}

-(NSString *)createModelMain{

    NSString *dictionaryString = @"";
    NSString *fmResultString = @"";
    NSString *encodeResultString = @"";
    NSString *decodeResultString = @"";
    
    for(VariableModel *varModel in resultArray){
        
        //Dict Result
        NSString *dictString = [NSString stringWithFormat:
                                    @"            self.%@ = [self %@:jsonDict[@\"%@\"]];\n", varModel.variableName, varModel.variableDict, varModel.variableName];
        
        dictionaryString = [dictionaryString stringByAppendingString:dictString];
        
        
        if(![varModel.variableType isEqualToString:@"NSArray"] && ![varModel.variableType isEqualToString:@"NSSet"]){
        
            //FM Result
            NSString *fmString = [NSString stringWithFormat:
                                  @"            self.%@ = [result %@:@\"%@\"];\n", varModel.variableName, varModel.variableFMResultSet, varModel.variableName];
            
            fmResultString = [fmResultString stringByAppendingString:fmString];
            
             //Decode Result
            NSString *decodeStr = [NSString stringWithFormat:
                                   @"           self.%@ = [decoder %@:@\"%@\"];\n", varModel.variableName, varModel.variableDecode, varModel.variableName];
            decodeResultString = [decodeResultString stringByAppendingString:decodeStr];
            
            
            //Encode Result
            NSString *encodeStr = [NSString stringWithFormat:
                                   @"           [encoder %@:self.%@ forKey:@\"%@\"];\n", varModel.variableEncode, varModel.variableName, varModel.variableName];
            encodeResultString = [encodeResultString stringByAppendingString:encodeStr];
        }
    
        
    }
    
    NSString *resultString = [NSString stringWithFormat:@"//Copy BaseModel From Spylight\n\n\n"
                              "#import \"%@.h\"\n"
                              "@implementation %@\n\n"
                              "-(id)initWithDictionary:(NSDictionary *)jsonDict{\n"
                              "     if(self=[super init]){\n"
                              "%@"
                              "     }\n"
                              "     return self;\n}\n"
                              "\n\n"
                              "-(id)initWithFMResultSet:(FMResultSet *)result{\n"
                              "    if(self = [super init]){\n"
                              "%@"
                              "     }\n"
                              "     return self;\n}\n"
                              "\n\n"
                              "-(id)initWithCoder:(NSCoder *)decoder{\n"
                              "     if(self=[super init]){\n"
                              "%@"
                              "     }\n"
                              "     return self;\n}\n"
                              "\n\n"
                              "-(void)encodeWithCoder:(NSCoder *)encoder{\n"
                              @"%@"
                              "}\n"
                              ,modelNameTextField.text, modelNameTextField.text, dictionaryString, fmResultString, decodeResultString, encodeResultString];
    
    return resultString;
}

-(NSString *)createModelHeader{
    NSString *variableString = @"";
    
    for(VariableModel *varMod in resultArray){
        
        NSString *varInString = [NSString stringWithFormat:@"@property (nonatomic, %@) %@%@%@\n", varMod.variableAssignType, varMod.variableType, varMod.variablePrimitive, varMod.variableName];
        
        variableString = [variableString stringByAppendingString:varInString];
    }


    NSString *resultString = [NSString stringWithFormat:@""
                                "#import <Foundation/Foundation.h>\n"
                                "#import <CoreData/CoreData.h>\n\n\n"
                                "@interface %@ : BaseModel\n\n"
                                "-(id)initWithDictionary:(NSDictionary *)jsonDict;\n"
                                "-(id)initWithFMResultSet:(FMResultSet *)result;\n"
                                "-(id)initWithCoder:(NSCoder *)decoder;\n"
                                "-(void)encodeWithCoder:(NSCoder *)encoder;\n\n"
                                "%@"
                                "\n@end", modelNameTextField.text, variableString];
    
    return resultString;
    
}

-(NSString *)createDatabaseStringWithIdString:(NSString *)idString{
    
    NSString *variableNameString = @"";
    NSString *questionMarkString = @"";
    NSString *objectString = @"";
    
    for(int i = 0; i < resultArray.count; i++){
        
        VariableModel *varModel = (VariableModel *)resultArray[i];
        
         if(![varModel.variableType isEqualToString:@"NSArray"] && ![varModel.variableType isEqualToString:@"NSSet"]){
            variableNameString = [variableNameString stringByAppendingString:
                                  [NSString stringWithFormat:@"%@%@", varModel.variableName, i<resultArray.count-1?@",":@""]];
            
            questionMarkString = [questionMarkString stringByAppendingString:
                                  [NSString stringWithFormat:@"?%@", i<resultArray.count-1?@",":@""]];
            
            objectString = [objectString stringByAppendingString:
                            [NSString stringWithFormat:@"%@%@",varModel.variableDefault, i<resultArray.count-1?@",":@""]
                            ];
         }
        
    }
    
    NSString *updateStr = [NSString stringWithFormat:@"         "
                           "success = [db executeUpdate:@\"INSERT INTO %@(%@) values(%@)\", "
                           "%@];", modelNameTextField.text, variableNameString, questionMarkString, objectString];
    
    NSString *resultString = [NSString stringWithFormat:@"#pragma mark - %@\n\n\n"
                              
                              "-(BOOL)update%@:(%@ *)obj{\n"
                              "     __block BOOL success = NO;\n\n"
                              "     [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {\n\n"
                              "         [db executeUpdate:@\"DELETE FROM '%@' WHERE %@=?\",obj.%@];\n"
                              "%@\n"
                              "     }];\n"
                              "     return success;\n"
                              "}\n\n\n"
                              
                              "-(NSArray *)getAll%@s{\n"
                              "     __block NSMutableArray *result = [NSMutableArray array];\n\n"
                              "     [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {\n\n"
                              "         FMResultSet *rs = [db executeQuery:@\"SELECT * FROM %@\"];\n\n"
                              "         while([rs next]) {\n"
                              "             %@ *%@ = [[%@ alloc] initWithFMResultSet:rs];\n"
                              "             [result addObject:%@];\n"
                              "         }\n"
                              "     }];\n\n"
                              "     return result;\n"
                              "}\n\n\n"
                              
                              "-(void)deleteAll%@s{\n"
                              "     [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {\n"
                              "         [db executeUpdate:@\"DELETE FROM %@\"];\n"
                              "     }];\n"
                              "}\n\n\n"
                              
                              "-(%@ *)get%@ById:(NSString *)primaryId{\n"
                              "     __block %@ *result = nil;\n\n"
                              "     [queue inTransaction:^(FMDatabase *db, BOOL *rollback) {\n\n"
                              "         NSString *queryString = [NSString stringWithFormat:@\"SELECT * FROM %@ WHERE %@='%%@'\", primaryId];\n"
                              "         FMResultSet *rs = [db executeQuery:queryString];\n"
                              "         if([rs next]) {\n"
                              "             result = [[%@ alloc] initWithFMResultSet:rs];\n"
                              "         }\n"
                              "     }];\n\n"
                              "     return result;\n"
                              "}\n\n\n",
                              
                              //pragma mark
                              modelNameTextField.text,
                              
                              //for UpdateObject
                              modelNameTextField.text, modelNameTextField.text,
                              modelNameTextField.text, idString, idString, updateStr,
                              
                              //for GetAllObjects
                              modelNameTextField.text,
                              modelNameTextField.text,
                              modelNameTextField.text, [modelNameTextField.text lowercaseString], modelNameTextField.text,
                              [modelNameTextField.text lowercaseString],
                              
                              //for DeleteAllObjects
                              modelNameTextField.text, modelNameTextField.text,
                              
                              //for GetObjectById
                              modelNameTextField.text, modelNameTextField.text,
                              modelNameTextField.text,
                              modelNameTextField.text, idString,
                              modelNameTextField.text
                              ];
    
    return resultString;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
