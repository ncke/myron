import Foundation

// MARK: - Standard Messaging

struct StandardMessaging: StandardModule {

    static let primitiveDefinitions = [

        MyronPrimitive(
            primitiveName: "messaging.send",
            representations: ["send"],
            signature: "({process} {any})",
            contextualBody: { args, context in
                let (fst, content) = try args.unwrap2(context.location)
                let destination = try fst.unwrapProcess(context.location)
                try context.send(content, to: destination)
                return .nothing
        }),

        MyronPrimitive(
            primitiveName: "messaging.receive",
            representations: ["receive"],
            signature: "()",
            contextualBody: { args, context in
                try args.mustHaveExactly(0, context.location)
                let message = try context.consumeMessage(where: { _ in true })
                if let message {
                    try context.setProcessState(to: .evaluating)
                    return message.content
                }

                try context.setProcessState(to: .waiting)
                return .nothing
        }),

        MyronPrimitive(
            primitiveName: "messaging.receive-from",
            representations: ["receive-from"],
            signature: "({process})",
            contextualBody: { args, context in
                let sender = try args.unwrap1(context.location).unwrapProcess(context.location)
                if let message = try context.consumeMessage(where: { m in m.source ==  sender}) {
                    try context.setProcessState(to: .evaluating)
                    return message.content
                }

                try context.setProcessState(to: .waiting)
                return .nothing
        })

    ]

}
