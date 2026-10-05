import Testing
@testable import MicropolisMac

struct MessagesTests {
    @Test
    func allMessagesHaveText() {
        let messages = Messages.engineMessages

        // Verify all messages have non-empty text
        for (index, text) in messages {
            #expect(index > 0)
            #expect(!text.isEmpty)
        }
    }

    @Test
    func messageCountMatches() {
        let messages = Messages.engineMessages

        // Should match the 18 messages in engineMessages.ts
        #expect(messages.count == 18)
    }

    @Test
    func allKeysSequentialFromOne() {
        let messages = Messages.engineMessages
        let sortedKeys = messages.keys.sorted()

        // Verify keys are what we expect
        let expectedKeys = [1, 2, 3, 4, 5, 6, 10, 11, 12, 20, 21, 22, 23, 24, 25, 26, 27, 29]
        #expect(sortedKeys == expectedKeys)
    }

    @Test
    func textFunctionHandlesInvalidIndex() {
        let negativeText = Messages.text(for: -1)
        #expect(negativeText.isEmpty)

        let missingText = Messages.text(for: 999)
        #expect(missingText.contains("City message"))
    }
}
