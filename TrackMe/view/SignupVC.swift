import UIKit
import Alamofire

class SignupVC: UIViewController {
    
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneNumberTextField: UITextField!
    
    @IBAction func signupPressed(_ sender: UIButton) {
        
        if let username = usernameTextField.text,
           let password = passwordTextField.text,
           let email = emailTextField.text,
           let phoneNumber = phoneNumberTextField.text {
            
            // [http 요청 헤더 지정]
            let header : HTTPHeaders = [
                "Content-Type" : "application/json"
            ]
            
            // [http 요청 파라미터 지정 실시]
            let bodyData : Parameters = [
                "username" : username,
                "password": password,
                "email": email,
                "phoneNumber": phoneNumber,
                "role": "ROLE_CUSTOMER"
            ]
            
            AF.request("http://localhost:8080/users/sign-up",
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
            self.navigationController?.popViewController(animated: true)
        }
    }
}
