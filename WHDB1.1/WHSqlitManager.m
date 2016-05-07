//
//  WHSqlitManager.m
//  WHSQLManager
//
//  Created by wuhaodes on 16/1/20.
//  Copyright © 2016年 wuhaodes. All rights reserved.
//

#import "WHDB.h"
#import <objc/runtime.h>
#import "WHSqlitManager.h"
@interface WHSqlitManager ()
{
   NSString *_dbName;
    NSDictionary *tableDictionary;
}
@property (nonatomic,strong)FMDatabaseQueue *dbQueue;
@end

@implementation WHSqlitManager
+(WHSqlitManager *)sharedSqlitManager{
    static WHSqlitManager *manager=nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager=[[WHSqlitManager alloc]init];
    });
    return manager;
}
-(BOOL)createDBWithDBPath:(NSString *)dbPath{
    [_dbQueue close];
    _dbQueue=nil;
    if (!_dbQueue) {
        
        _dbQueue=[FMDatabaseQueue  databaseQueueWithPath:dbPath];
        NSLog(@"%@",dbPath);
    }
    return YES;
}
-(BOOL)createDBWithDBName:(NSString *)name{
    NSString *docPath=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    if (name==nil) {
        _dbName=@"class.db";
        docPath=[docPath stringByAppendingPathComponent:_dbName];
    }
    else{
        _dbName=name;
        docPath=[docPath stringByAppendingPathComponent:_dbName];
    }
    return [self createDBWithDBPath:docPath];
}


-(BOOL)createTableWithModelClass:(id)modelClass UseTableName:(NSString *)tableName{
    return [self createTableWithModelClass:modelClass UseTableName:tableName PrimaryKeyIndex:-9999];
}

-(BOOL)createTableWithModelClass:(id)modelClass UseTableName:(NSString *)tableName PrimaryKeyIndex:(NSInteger)index{
    if (modelClass==nil) {
        return NO;
    }
    NSString *className=NSStringFromClass(modelClass);
    if (tableName==nil) {
        tableName=className;
    }
    NSString *sql_relationship=@"CREATE TABLE IF NOT EXISTS  relationship(tableName text PRIMARY KEY,modelName text)";
    [_dbQueue inDatabase:^(FMDatabase *db) {
        [db executeUpdate:sql_relationship];
        
    }];
    NSString *sql_select=[NSString stringWithFormat:@"select * from relationship where tablename='%@'",tableName];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        if (![[db executeQuery:sql_select] next]) {
            NSString *sql_insert=[NSString stringWithFormat:@"insert into relationship(tableName,modelName) values('%@','%@')",tableName,className];
            [db executeUpdate:sql_insert];
        }
    }];
    // 初始化一个装sql的可变string
    NSMutableString *sql_creat=[NSMutableString stringWithFormat:@"CREATE TABLE IF NOT EXISTS %@(", tableName];
    const char * cClassName=[className UTF8String];
    id classM = objc_getClass(cClassName);
    // i 计数 、  outCount 放我们的属性个数
    unsigned int outCount;
    // 反射得到属性的个数
    objc_property_t * properties = class_copyPropertyList(classM, &outCount);
    // 循环 得到属性名称  拼接数据库语句
    for (int i = 0; i < outCount; i++) {
        objc_property_t property = properties[i];
        
        // 获得属性名称
        NSString * attributeName = [NSString stringWithUTF8String:property_getName(property)];
        if (i==index) {
            [sql_creat appendFormat:@"%@ TEXT PRIMARY KEY,",attributeName];
            continue;
        }
        if (i == outCount - 1)
        {
            [sql_creat appendFormat:@"%@ TEXT)", attributeName];
            break;
        }
        [sql_creat appendFormat:@"%@ TEXT,",attributeName];
    }
    __block  BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result=[db executeUpdate:sql_creat];
    }];
    return result;
}

-(BOOL)insertDataIntoTable:(NSString *)tableName WithModel:(id)model{
    NSLog(@"%@",model);
    if (tableName==nil||model==nil) {
        return NO;
    }
    NSString *className=NSStringFromClass([model class]);
    unsigned int outCount;
    const char * cClassName=[className UTF8String];
    id classM=objc_getClass(cClassName);
    objc_property_t *properties=class_copyPropertyList(classM, &outCount);
    NSMutableString *sql_insert=[NSMutableString stringWithFormat:@"insert into %@(",tableName];
    NSMutableArray *arr=[NSMutableArray array];
    for (int i=0; i<outCount; i++) {
        objc_property_t property=properties[i];
        NSString *attributeName=[NSString stringWithUTF8String:property_getName(property)];
        NSString *str=[model valueForKey:attributeName];
        if(str==nil){
            str=@"";
        }
        [arr addObject:str];
        if (i==outCount-1) {
            [sql_insert appendFormat:@"%@)",attributeName];
            break;
        }
        [sql_insert appendFormat:@"%@,",attributeName];
    }
    [sql_insert appendFormat:@"values("];
    for (int j=0; j<arr.count; j++) {
        if (j==arr.count-1) {
            [sql_insert appendFormat:@"'%@')",arr[j]];
            break;
        }
        [sql_insert appendFormat:@"'%@',",arr[j]];
    }
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result=[db executeUpdate:sql_insert];
    }];
    return result;
}
-(BOOL)deleteInTable:(NSString *)tableName andWhere:(NSString *)whereSql{
    if (tableName==nil) {
        return NO;
    }
    NSMutableString *sql_delete=[NSMutableString stringWithFormat:@"delete from %@",tableName];
    if (whereSql!=nil) {
        [sql_delete appendFormat:@"where %@",whereSql];
    }
    __block BOOL ret;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        ret=[db executeUpdate:sql_delete];
    }];
    return ret;
}
-(BOOL)deleteAllDataInTable:(NSString *)tableName{
    BOOL result=[self deleteInTable:tableName andWhere:nil];
    return result;
}
-(BOOL)dropTable:(NSString *)tableName{
    if (tableName==nil) {
        return NO;
    }
    NSString *sql_drop=[NSString stringWithFormat:@"drop table %@",tableName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
          result=[db executeUpdate:sql_drop];
    }];
    return result;
}
-(BOOL)dropAllTables{
    [self dropDataBase];
    [self createDBWithDBName:_dbName];
    return YES;
}
-(BOOL)dropDataBase{
    NSString *sql_drop_dataBase=[NSString stringWithFormat:@"drop database %@",_dbName];
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
       result =[db executeUpdate:sql_drop_dataBase];
    }];
    
    return result;
}
-(BOOL)updateInTable:(NSString *)tableName andSet:(NSString *)setSql{
   BOOL result=[self updateInTable:tableName andSet:setSql andWhere:nil];
    return result;
}
-(BOOL)updateInTable:(NSString *)tableName andSet:(NSString *)setSql andWhere:(NSString *)whereSql{
    if (tableName==nil||setSql==nil) {
        return NO;
    }
    NSMutableString *sql_update=[NSMutableString stringWithFormat:@"update %@ set %@",tableName,setSql];
    if (whereSql!=nil) {
        [sql_update appendFormat:@" where %@ ",whereSql];
    }
    __block BOOL result;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        result=[db executeUpdate:sql_update];
    }];
  
    return result;
}
///select
//all
-(void)selectInTable:(NSString *)tableName dataModelBlock:(SendData)block{
     [self selectInTable:tableName andLimit:-9999 dataModelBlock:block];
}
//all +limit
-(void)selectInTable:(NSString *)tableName andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
   [self selectInTable:tableName andWhere:nil andLimit:limit dataModelBlock:block];
}

///where
//where
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql dataModelBlock:(SendData)block{
   [self selectInTable:tableName andWhere:whereSql andLimit:-9999 dataModelBlock:block];
}
//where + limit
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
   [self selectIntable:tableName selectTypes:nil andWhere:whereSql andLimit:limit dataModelBlock:block];
}
//where + order by +sqlType
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block{
    [self selectInTable:tableName selectTypes:nil andOrderby:oder WithsqlType:sqlType dataModelBlock:block];
}
//where + oder by +sqlType+limit
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
  [self selectIntable:tableName selectTypes:nil andWhere:whereSql andOderby:oder WithsqlType:sqlType andGroupby:nil andLimit:limit dataModelBlock:block];
}
//where +sqlTypes
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql dataModelBlock:(SendData)block{
    [self selectIntable:tableName selectTypes:sqlTypes andWhere:whereSql andLimit:-9999 dataModelBlock:block];
}
//where +sqlTypes +limit
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
   [self selectIntable:tableName selectTypes:sqlTypes andWhere:whereSql andOderby:NONE WithsqlType:nil andLimit:limit dataModelBlock:block];
}
//where +sqlTypes+order by + sqlType
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block{
   [self selectIntable:tableName selectTypes:sqlTypes andWhere:whereSql andOderby:oder WithsqlType:sqlType andLimit:-9999 dataModelBlock:block];
}
//where +sqlTypes+order by + sqlType+limit
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
   [self selectIntable:tableName selectTypes:sqlTypes andWhere:whereSql andOderby:oder WithsqlType:sqlType andGroupby:nil andLimit:limit dataModelBlock:block];
}
///oder by
//oderby +sqlType
-(void)selectInTable:(NSString *)tableName andOrderby:(Order)order WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block{
     [self selectInTable:tableName selectTypes:nil andOrderby:order WithsqlType:sqlType dataModelBlock:block];
}
//sqlTypes+oderby+sqlType
-(void)selectInTable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andOrderby:(Order)order WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block{
    [self selectInTable:tableName selectTypes:sqlTypes andOrderby:order WithsqlType:sqlType andLimit:-9999 dataModelBlock:block];
}
//sqlTypes+oderby+sqlType+limit
-(void)selectInTable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andOrderby:(Order)order WithsqlType:(NSString *)sqlType andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
   [self selectIntable:tableName selectTypes:sqlTypes andWhere:nil andOderby:order WithsqlType:sqlType andLimit:limit dataModelBlock:block];
}

///group
//group
-(void)selectInTable:(NSString *)tableName andGroupby:(NSString *)groupSql dataModelBlock:(SendData)block{
     [self selectInTable:tableName andGroupby:groupSql andLimit:-9999 dataModelBlock:block];
}
//sqlTypes+group
-(void)selectInTable:(NSString *)tableName selectType:(NSString *)sqlTypes andGroupby:(NSString *)groupSql dataModelBlock:(SendData)block{
    [self selectInTable:tableName selectTypes:sqlTypes andGroupby:groupSql andLimit:-9999 dataModelBlock:block];
}
//group+limit
-(void)selectInTable:(NSString *)tableName andGroupby:(NSString *)groupSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
    [self selectInTable:tableName selectTypes:nil andGroupby:groupSql andLimit:limit dataModelBlock:block];
}
//sqlTypes+group+limit
-(void)selectInTable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andGroupby:(NSString *)groupSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
    [self selectIntable:tableName selectTypes:sqlTypes andWhere:nil andOderby:NONE WithsqlType:nil andGroupby:groupSql andLimit:limit dataModelBlock:block];
}

//all satuations
//where +sqlTypes+order by+group+sqlType+limit
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)type andGroupby:(NSString *)groupSql  andLimit:(NSInteger)limit dataModelBlock:(SendData)block{
    NSMutableString *sql_select=[NSMutableString string];
    if (tableName==nil) {
        NSLog(@"please give a name of table");
        return;
    }
    else{
        if (sqlTypes==nil) {
            [sql_select appendFormat:@"select * from %@ ",tableName];
        }
        else{
            [sql_select appendFormat:@"select %@ from %@ ",sqlTypes,tableName];
        }
        if (whereSql!=nil) {
            [sql_select appendFormat:@"where %@ ",whereSql];
        }
        if (groupSql!=nil) {
            [sql_select appendFormat:@"group by %@",groupSql];
        }
        if(type!=nil){
            switch (oder) {
                case NONE:
                    NSLog(@"please give a right order");
                    break;
                case ASC:
                    [sql_select appendFormat:@"order by %@ asc ",type];
                    break;
                case DESC:
                    [sql_select appendFormat:@"order by %@ desc ",type];
                    break;
            }
        }
        if (limit>0) {
            [sql_select appendFormat:@"limit %@",@(limit)];
        }
        
    }
    NSMutableArray *keys=[NSMutableArray array];
    NSString *sql_table=[NSString stringWithFormat:@"select * from relationship where tableName='%@'",tableName];
    __block  NSString *className;
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *ret=[db executeQuery:sql_table];
        while ([ret next]) {
            className=[ret stringForColumn:@"modelName"];
        }
        const char * cClassName=[className UTF8String];
        id classM = objc_getClass(cClassName);
        // i 计数 、  outCount 放我们的属性个数
        unsigned int outCount;
        // 反射得到属性的个数
        objc_property_t * properties = class_copyPropertyList(classM, &outCount);
        // 循环 得到属性名称  拼接数据库语句
        for (int i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            // 获得属性名称
            NSString * attributeName = [NSString stringWithUTF8String:property_getName(property)];
            [keys addObject:attributeName];
        }
    }];
    NSMutableArray *resutlArr=[NSMutableArray array];
    [_dbQueue inDatabase:^(FMDatabase *db) {
        FMResultSet *set=[db executeQuery:sql_select];
        while ([set next]) {
            NSMutableArray *values=[NSMutableArray array];
            for (int i=0; i<[set columnCount]; i++) {
                NSString *str=[set stringForColumnIndex:i];
                [values addObject:(id)str];
            }
            NSMutableDictionary *dict=[[NSMutableDictionary alloc]initWithObjects:values forKeys:keys];
            Class class=NSClassFromString(className);
            id model=[[class alloc]init];
            [model setValuesForKeysWithDictionary:dict];
            [resutlArr addObject:model];
        }
        block(resutlArr);
    }];

}
@end

