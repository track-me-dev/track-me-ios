import UIKit
import Alamofire
import KeychainSwift

class LoginVC: UIViewController {
    
    @IBOutlet weak var usernameTextFied: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var failTextField: UITextField!
    
    @IBAction func loginPressed(_ sender: UIButton) {
        if let username = usernameTextFied.text, let password = passwordTextField.text {
            // [http 요청 헤더 지정]
            let header : HTTPHeaders = [
                "Content-Type" : "application/json"
            ]
            
            // [http 요청 파라미터 지정 실시]
            let bodyData : Parameters = [
                "username" : username,
                "password": password
            ]
            
            AF.request("http://localhost:8080/users/login",
                       method: .post,
                       parameters: bodyData, // [전송 데이터]
                       encoding: JSONEncoding.default, // [인코딩 스타일]
                       headers: header // [헤더 지정]
            )
            .validate(statusCode: 200..<300)
            .response { response in
                switch response.result {
                case .success(let value):
                    do {
                        self.failTextField.isHidden = true
                        let result = try JSONDecoder().decode(UserTokenResponse.self, from: value!)
                        let keychain = KeychainSwift()
                        
                        keychain.set(result.accessToken, forKey: "trackme_accessToken")
                        keychain.set(result.accessToken, forKey: "trackme_refreshToken")
                        let destinationVC = UIStoryboard(name: "Main", bundle: nil)
                            .instantiateViewController(withIdentifier: "MainViewController") as! MainVC
//                        self.present(destinationVC, animated: true, completion: nil)
                        self.show(destinationVC, sender: nil)
                        print("log in success")
                    } catch {
                        print(error)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.failTextField.isHidden = false
                        self.failTextField.text = "아이디와 비밀번호를 확인해주세요."
                    }
                    print(error)
                    break;
                }
            }
        }
    }
    
}
