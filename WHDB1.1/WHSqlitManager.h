//
//  WHSqlitManager.h
//  WHSQLManager
//
//  Created by wuhaodes on 16/1/20.
//  Copyright © 2016年 wuhaodes. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SendData)(NSArray *modelArray);

typedef NS_ENUM(NSInteger,Order){
    NONE,
    ASC,
    DESC
};
@interface WHSqlitManager : NSObject



+(WHSqlitManager *)sharedSqlitManager;
///creat and open
//create and open database
-(BOOL)createDBWithDBPath:(NSString *)dbPath;
///creat and open
//create and open database
-(BOOL)createDBWithDBName:(NSString *)name;
//create table with the class of model and table name
-(BOOL)createTableWithModelClass:(id)modelClass UseTableName:(NSString *)tableName;
-(BOOL)createTableWithModelClass:(id)modelClass UseTableName:(NSString *)tableName PrimaryKeyIndex:(NSInteger)index;

///insert
//insert into table with datamodel
-(BOOL)insertDataIntoTable:(NSString *)tableName WithModel:(id)model;


///delete and drop
//delete data in table where wheresql
-(BOOL)deleteInTable:(NSString *)tableName andWhere:(NSString *)whereSql;
//delete all data in table
-(BOOL)deleteAllDataInTable:(NSString *)tableName;
// delete whole table lead to the table is not exsists
-(BOOL)dropTable:(NSString *)tableName;
// delete all table  lead to only database
-(BOOL)dropAllTables;
//delete current database lead to the database is not exsists
-(BOOL)dropDataBase;

///update
//update table data set  use setSql where whereSql
-(BOOL)updateInTable:(NSString *)tableName andSet:(NSString *)setSql andWhere:(NSString *)whereSql;
-(BOOL)updateInTable:(NSString *)tableName andSet:(NSString *)setSql;

///select
//all
-(void)selectInTable:(NSString *)tableName dataModelBlock:(SendData)block;
//all +limit
-(void)selectInTable:(NSString *)tableName andLimit:(NSInteger)limit dataModelBlock:(SendData)block;

///where
//where
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql dataModelBlock:(SendData)block;
//where + limit
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block;
//where + order by +sqlType
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block;
//where + oder by +sqlType+limit
-(void)selectInTable:(NSString *)tableName andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType andLimit:(NSInteger)limit dataModelBlock:(SendData)block;
//where +sqlTypes
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql dataModelBlock:(SendData)block;
//where +types +limit
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block;
//where +sqlTypes+order by + sqlType
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block;
//where +sqlTypes+order by + sqlType+limit
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)sqlType andLimit:(NSInteger)limit dataModelBlock:(SendData)block;

///oder by
//oderby +sqlType
-(void)selectInTable:(NSString *)tableName andOrderby:(Order)order WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block;
//sqlTypes+oderby+sqlType
-(void)selectInTable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andOrderby:(Order)order WithsqlType:(NSString *)sqlType dataModelBlock:(SendData)block;
//sqlTypes+oderby+sqlType+limit
-(void)selectInTable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andOrderby:(Order)order WithsqlType:(NSString *)sqlType andLimit:(NSInteger)limit dataModelBlock:(SendData)block;

///group
//group
-(void)selectInTable:(NSString *)tableName andGroupby:(NSString *)groupSql dataModelBlock:(SendData)block;
//sqlTypes+group
-(void)selectInTable:(NSString *)tableName selectType:(NSString *)sqlTypes andGroupby:(NSString *)groupSql dataModelBlock:(SendData)block;
//group+limit
-(void)selectInTable:(NSString *)tableName andGroupby:(NSString *)groupSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block;
//sqlTypes+group+limit
-(void)selectInTable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andGroupby:(NSString *)groupSql andLimit:(NSInteger)limit dataModelBlock:(SendData)block;

//all satuations
//where +sqlTypes+order by+group+sqlType+limit
-(void)selectIntable:(NSString *)tableName selectTypes:(NSString *)sqlTypes andWhere:(NSString *)whereSql andOderby:(Order)oder WithsqlType:(NSString *)type andGroupby:(NSString *)groupSql  andLimit:(NSInteger)limit dataModelBlock:(SendData)block;

/***************************groupby比较复杂暂未实现*********************/



@end
