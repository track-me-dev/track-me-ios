//
//  LoginVC.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/09/29.
//

import UIKit
import Alamofire

class LoginVC: UIViewController {
    
    @IBOutlet weak var usernameTextFied: UITextField!
    @IBOutlet weak var passwordTexField: UITextField!
    
    @IBAction func loginPressed(_ sender: UIButton) {
        if let username = usernameTextFied.text, let password = passwordTexField.text {
            // [http 요청 헤더 지정]
            let header : HTTPHeaders = [
                "Content-Type" : "application/json"
            ]
            
            // [http 요청 파라미터 지정 실시]
            let bodyData : Parameters = [
                "path" : username,
                "password": password
            ]
            
            AF.request("http://localhost:8080/users/login",
                       method: .post,
                       parameters: bodyData, // [전송 데이터]
                       encoding: JSONEncoding.default, // [인코딩 스타일]
                       headers: header // [헤더 지정]
            )
            .validate(statusCode: 200..<300)
            .responseData { response in
                switch response.result {
                case .success(_):
                    print("log in success")
                case .failure(let error):
                    print(error)
                    break;
                }
            }
        }
    }
    
}
