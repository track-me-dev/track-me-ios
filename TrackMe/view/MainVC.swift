import UIKit

class MainVC: UIViewController {
    
    
    @IBOutlet weak var createTrackTextView: UITextView!
    @IBOutlet weak var searchTrackTextView: UITextView!
    @IBOutlet weak var createTrackImageView: UIImageView!
    @IBOutlet weak var searchTrackImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.titleView = TitleRenderer.renderTitle()
        
        createTrackTextView.text = "나만의 트랙을 만들어\n사람들과 함께\n공유해보세요!"
        createTrackImageView.layer.cornerRadius = 10
        createTrackImageView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMinXMaxYCorner]
        
        searchTrackTextView.text = "사람들과 함께\n경쟁할 수도 있어요!"
        searchTrackImageView.layer.cornerRadius = 10
        searchTrackImageView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        
    }
}
