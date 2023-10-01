import UIKit

class TitleRenderer {
    
    static func renderTitle() -> UILabel? {
        if let fontURL = Bundle.main.url(forResource: "NanumSquareNeo-eHv", withExtension: "ttf"),
           let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
           let fontRef = CGFont(fontDataProvider)
        {
            CTFontManagerRegisterGraphicsFont(fontRef, nil)
            if let fontName = fontRef.postScriptName as String? {
                if let customFont = UIFont(name: fontName, size: 30) {
                    let fontMetrics = UIFontMetrics(forTextStyle: .headline)
                    let adjustedFont = fontMetrics.scaledFont(for: customFont)
                    
                    let attachment = NSTextAttachment()
                    attachment.image = UIImage(named: "TrackMeAppIcon")
                    attachment.bounds = CGRect(x: 0, y: -10, width: 40, height: 40)
                    
                    // Create an attributed string with the text attachment.
                    let attributedString = NSMutableAttributedString(attachment: attachment)
                    attributedString.append(NSAttributedString(string: " TrackMe ", attributes: [
                        .font : adjustedFont,
                        .foregroundColor : UIColor(named: "SubColor") as Any,
                    ]))
                    attributedString.append(NSAttributedString(attachment: attachment))
                    
                    let label = UILabel()
                    label.attributedText = attributedString
                    return label
                }
            }
        }
        return nil
    }
}
