/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package electricity.bill.management;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 *
 * @author shiva
 */
public class ConnDb {
    public static Connection conLink() throws SQLException {
        DriverManager.registerDriver(new oracle.jdbc.OracleDriver());
        Connection con=DriverManager.getConnection("jdbc:oracle:thin:@localhost:1521:xe","electricity_user","electricity_pass");
        return con;
    }
}
