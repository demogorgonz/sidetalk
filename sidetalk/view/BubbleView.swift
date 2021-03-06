
import Foundation

enum BubbleColor { case Foreign, Own, Compose, Title; }
enum CalloutSide { case Left, Right; }
class BubbleView: NSView {
    private let shapeLayer = CAShapeLayer();

    private var _calloutSide: CalloutSide = .Left;
    var calloutSide: CalloutSide {
        get { return self._calloutSide; }
        set { self._calloutSide = newValue; self.relayout(); }
    };

    private var _calloutShown: Bool = true;
    var calloutShown: Bool {
        get { return self._calloutShown; }
        set { self._calloutShown = newValue; self.relayout(); }
    };

    private var _color: BubbleColor?;
    var color: BubbleColor? {
        get { return self._color; }
        set {
            self._color = newValue;
            switch newValue {
            case .none:             fallthrough;
            case .some(.Foreign):   self.shapeLayer.fillColor = ST.message.bgForeign;
                                    self.shapeLayer.strokeColor = ST.message.outlineForeign;
            case .some(.Own):       self.shapeLayer.fillColor = ST.message.bgOwn;
                                    self.shapeLayer.strokeColor = ST.message.outlineOwn;
            case .some(.Compose):   self.shapeLayer.fillColor = ST.conversation.composeBg;
                                    self.shapeLayer.strokeColor = ST.conversation.composeOutline;
            case .some(.Title):     self.shapeLayer.fillColor = ST.message.bgTitle;
                                    self.shapeLayer.strokeColor = ST.message.outlineTitle;
            }
        }
    };

    override func viewWillMove(toSuperview view: NSView?) {
        self.wantsLayer = true;
        super.viewWillMove(toSuperview: view);

        if self._color == nil { self.color = .Foreign; }
        self.shapeLayer.lineWidth = ST.message.outlineWidth;
        self.layer!.addSublayer(self.shapeLayer);
    }

    override func setFrameSize(_ newSize: NSSize) {
        super.setFrameSize(newSize);
        self.relayout();
    }

    private func relayout() {
        // bail if we're not going to get real numbers. TODO: just bail, or bail and clearpath?
        if self.frame.width == 0 || self.frame.height == 0 { return; }

        // draw bubble.
        let origin = NSPoint(x: (self.calloutSide == .Left) ? ST.message.calloutSize : 0, y: 0);
        let width = self.frame.size.width - ST.message.calloutSize - ((self.calloutSide == .Right) ? ST.message.outlineWidth : 0);
        let size = NSSize(width: width, height: self.frame.size.height);
        let rect = NSRect(origin: origin, size: size).insetBy(dx: ST.message.outlineWidth, dy: ST.message.outlineWidth);

        // draw the entire path manually on account of no merge operations for the callout.
        let path = NSBezierPath();

        // start at the top-right, before the curve.
        let topRight = CGPoint(x: rect.origin.x + rect.width, y: rect.origin.y + rect.height);
        path.move(to: CGPoint(x: topRight.x - ST.message.radius, y: topRight.y));
        path.curve(to: CGPoint(x: topRight.x, y: topRight.y - ST.message.radius), controlPoint1: topRight, controlPoint2: topRight)

        // draw callout if it's on the right.
        if self.calloutShown && self.calloutSide == .Right {
            path.addLine(to: CGPoint(x: topRight.x, y: ST.message.calloutVline + ST.message.calloutSize));
            path.addLine(to: CGPoint(x: topRight.x + ST.message.calloutSize, y: ST.message.calloutVline));
            path.addLine(to: CGPoint(x: topRight.x, y: ST.message.calloutVline - ST.message.calloutSize));
        }

        // now the bottom-right.
        let bottomRight = CGPoint(x: topRight.x, y: rect.origin.y);
        path.addLine(to: CGPoint(x: bottomRight.x, y: bottomRight.y + ST.message.radius));
        path.curve(to: CGPoint(x: bottomRight.x - ST.message.radius, y: bottomRight.y), controlPoint1: bottomRight, controlPoint2: bottomRight);

        // and the bottom-left.
        let bottomLeft = rect.origin;
        path.addLine(to: CGPoint(x: bottomLeft.x + ST.message.radius, y: bottomLeft.y));
        path.curve(to: CGPoint(x: bottomLeft.x, y: bottomLeft.y + ST.message.radius), controlPoint1: bottomLeft, controlPoint2: bottomLeft);

        // now draw callout if it's on the left.
        if self.calloutShown && self.calloutSide == .Left {
            path.addLine(to: CGPoint(x: bottomLeft.x, y: ST.message.calloutVline - ST.message.calloutSize));
            path.addLine(to: CGPoint(x: bottomLeft.x - ST.message.calloutSize, y: ST.message.calloutVline));
            path.addLine(to: CGPoint(x: bottomLeft.x, y: ST.message.calloutVline + ST.message.calloutSize));
        }

        // top-left, and close.
        let topLeft = CGPoint(x: rect.origin.x, y: topRight.y);
        path.addLine(to: CGPoint(x: topLeft.x, y: topLeft.y - ST.message.radius));
        path.curve(to: CGPoint(x: topLeft.x + ST.message.radius, y: topLeft.y), controlPoint1: topLeft, controlPoint2: topLeft);
        path.close();

        self.shapeLayer.path = path.cgPath;
    }
}
