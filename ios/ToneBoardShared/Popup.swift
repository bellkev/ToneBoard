//
//  Popup.swift
//  ToneBoard
//
//  Created by Kevin Bell on 1/7/22.
//

import SwiftUI

struct Popup: Shape {
    
    let innerWidth: CGFloat
    let topRadius: CGFloat
    let bottomRadius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        let curveStrength = topRadius * 1.5
        let top = rect.minY
        let bottom = rect.maxY
        let left = rect.minX
        let right = rect.maxX
        let midY = rect.midY + rect.height / 10
        let midLeftX = rect.midX - innerWidth / 2
        let midRightX = rect.midX + innerWidth / 2
        
        let p1 = CGPoint(x: midLeftX, y: midY)
        let p2 = CGPoint(x: left, y: midY - topRadius * 2)
        let c1 = CGPoint(x: p1.x, y: p1.y - curveStrength)
        let c2 = CGPoint(x: p2.x, y: p2.y + curveStrength)
        let p3 = CGPoint(x: left, y: top + topRadius)
        let p4 = CGPoint(x: left, y: top)
        let p5 = CGPoint(x: left + topRadius, y: top)
        let p6 = CGPoint(x: right - topRadius, y: top)
        let p7 = CGPoint(x: right, y: top)
        let p8 = CGPoint(x: right, y: top + topRadius)
        let p9 = CGPoint(x: right, y: midY - topRadius * 2)
        let p10 = CGPoint(x: midRightX, y: midY)
        let c9 = CGPoint(x: p9.x, y: p9.y + curveStrength)
        let c10 = CGPoint(x: p10.x, y: p10.y - curveStrength)
        let p11 = CGPoint(x: midRightX, y: bottom - bottomRadius)
        let p12 = CGPoint(x: midRightX, y: bottom)
        let p13 = CGPoint(x: midRightX - bottomRadius, y: rect.maxY)
        let p14 = CGPoint(x: midLeftX + bottomRadius, y: bottom)
        let p15 = CGPoint(x: midLeftX, y: bottom)
        let p16 = CGPoint(x: midLeftX, y: bottom - bottomRadius)
        
        path.move(to: p1)
        path.addCurve(to: p2, control1: c1, control2: c2)
        path.addLine(to: p3)
        path.addArc(tangent1End: p4, tangent2End: p5, radius: topRadius)
        path.addLine(to: p6)
        path.addArc(tangent1End: p7, tangent2End: p8, radius: topRadius)
        path.addLine(to: p9)
        path.addCurve(to: p10, control1: c9, control2: c10)
        path.addLine(to: p11)
        path.addArc(tangent1End: p12, tangent2End: p13, radius: bottomRadius)
        path.addLine(to: p14)
        path.addArc(tangent1End: p15, tangent2End: p16, radius: bottomRadius)
        return path
    }
}

struct Popup_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Rectangle().fill(.red).frame(width: 200, height: 400)
            Popup(innerWidth: 100, topRadius: 40, bottomRadius: 15).frame(width: 200, height: 400)
        }
    }
}
