import UIKit

struct Random {

  static func integer(min: Int, max: Int) -> Int {
    return min + Int(arc4random_uniform(UInt32(max - min + 1)))
  }

  static func sentence() -> String {
    let src = """
      They got there early, and they got really good seats.
      She works two jobs to make ends meet; at least, that was her reason for not having
      time to join us.
      I am never at home on Sundays.
      A purple pig and a green donkey flew a kite in the middle of the night and ended up sunburnt.
      The stranger officiates the meal.
      This is a Japanese doll.
      A song can make or ruin a person’s day if they let it get to them.
      She borrowed the book from him many years ago and hasn't yet returned it.
      He didn’t want to go to the dentist, yet he went anyway.
      Wednesday is hump day, but has anyone asked the camel if he’s happy about it?
      The waves were crashing on the shore; it was a lovely sight.
      I think I will buy the red car, or I will lease the blue one.
      This is the last random sentence I will be writing and I am going to stop mid-sent
      Check back tomorrow; I will see if the book has arrived.
      The river stole the gods.
      She wrote him a long letter, but he didn't read it.
      There was no ice cream in the freezer, nor did they have money to go to the store.
      She advised him to come back at once.
      Sixty-Four comes asking for bread.
      I'd rather be a bird than a fish.
      She always speaks to him in a loud voice.
      He turned in the research paper on Friday; otherwise, he would have not passed the class.
      What was the person thinking when they discovered cow’s milk was fine for human consumption
      and why did they do it in the first place!?
      I love eating toasted cheese and tuna sandwiches.
      I will never be this young again. Ever. Oh damn… I just got older.
      I checked to make sure that he was still alive.
      He told us a very exciting adventure story.
      It was getting dark, and we weren’t there yet.
      She did not cheat on the test, for it was not the right thing to do.
      Sometimes, all you need to do is completely make an ass of yourself and laugh it off to
      realise that life isn’t so bad after all.
      He ran out of money, so he had to stop playing poker.
      Where do random thoughts come from?
      The memory we used to share is no longer coherent.
      Joe made the sugar cookies; Susan decorated them.
      Wow, does that work?
      The book is in front of the table.
      Writing a list of random sentences is harder than I initially thought it would be.
      There were white out conditions in the town; subsequently, the roads were impassable.
      Abstraction is often one floor above you.
      I am happy to take your donation; any amount will be greatly appreciated.
      We need to rent a room for our party.
      Let me help you with your baggage.
      She only paints with bold colors; she does not like pastels.
      Two seats were vacant.
      Rock music approaches at high velocity.
      Mary plays the piano.
      Sometimes it is better to just walk away from things and go back to them later when you’re
      in a better frame of mind.
      Christmas is coming.
      A glittering gem is not enough.
      Don't step on the broken glass.
      Hurry!
      The body may perhaps compensates for the loss of a true metaphysics.
      The clock within this blog and the clock on my laptop are 1 hour different from each other.
      The old apple revels in its authority.
      She did her best to help him.
      We have a lot of rain in June.
      Malls are great places to shop; I can find everything I need under one roof.
      Everyone was busy, so I went to the movie alone.
      Should we start class now, or should we wait for everyone to get here?
      My Mum tries to be cool by saying that she likes all the same things that I do.
      Last Friday in three week’s time I saw a spotted striped blue worm shake hands with a
      legless lizard.
      I want to buy a onesie… but know it won’t suit me.
      I hear that Nancy is very pretty.
      She folded her handkerchief neatly.
      She was too short to see over the fence.
      Tom got a small piece of pie.
      If the Easter Bunny and the Tooth Fairy had babies would they take your teeth and
      leave chocolate for you?
      The sky is clear; the stars are twinkling.
      The shooter says goodbye to his love.
      How was the math test?
      I currently have 4 windows open up… and I don’t know why.
      Italy is my favorite country; in fact, I plan to spend two weeks there next year.
      The quick brown fox jumps over the lazy dog.
      I would have gotten the promotion, but my attendance wasn’t good enough.
      Cats are good pets, for they are clean and are not noisy.
      I often see the time 11:11 or 12:34 on clocks.
      I was very proud of my nickname throughout high school but today- I couldn’t be any
      different to what my nickname was.
      The mysterious diary records the voice.
      We have never been to Asia, nor have we visited Africa.
      I want more detailed information.
      If I don’t like something, I’ll stay away from it.
      The lake is a long way from here.
      Yeah, I think it's a good environment for learning English.
      When I was little I had a car door slammed shut on my hand. I still remember it quite vividly.
      Please wait outside of the house.
      I really want to go to work, but I am too sick to drive.
      Someone I know recently combined Maple Syrup & buttered Popcorn thinking it would taste like
      caramel popcorn. It didn’t and they don’t recommend anyone else do it either.
      He said he was not there yesterday; however, many people saw him there.
      If Purple People Eaters are real… where do they find purple people to eat?
      Lets all be unique together until we realise we are all the same.
      Is it free?
      I am counting my calories, yet I really want dessert.
      If you like tuna and tomato sauce- try combining the two. It’s really not as bad as it sounds.
      """
      let components = src.split(separator: ".").map {
        String($0).replacingOccurrences(of: "\n", with: "")
      }
      return components[Random.integer(min: 0, max: components.count-1)]
  }

  static func name() -> String {
    let src = """
      Schuyler Ripley
      Cinnamon Ruben
      Skip Macneill
      Denni Unwin
      Pren Swenson
      Ashlie Vasi
      Edwin Heald
      Janel Seibel
      Garwin Heaney
      Gwendolin Posa
      Araldo Trenholm
      Judie Mcevoy
      Anton Shirey
      Tova Chalmers
      Matty Goode
      Stacie Lax
      Gibbie Sirel
      Eilis Rangan
      Jonah Larsgaard
      Candide Crim
      Birch Rushing
      Petronella Gonano
      Reggie Mekalanos
      Melody Ahmad-obeid
      Kelbee Soper
      Ambur Rosenfeld
      Rudy Unwin
      Ericha Marton
      Kenyon Seibel
      Philomena Ciampi
      Marcel Mcevoy
      Dominique Ramsay
      Gerick Lax
      Jesselyn Pimm
      Gearalt Crim
      Odele Brisebois
      Colman Ahmad-obeid
      Carla Schoffel
      Wilhelm Marton
      Tamar Croxen
      Ethan Ramsay
      Shirline Schock
      Krishna Brisebois
      Astrix Lent
      August Croxen
      Shawn Brandenberg-horn
      Moshe Lent
      Luisa Dobson
      Konstantin Dobson
      Garreth Chesson
      """
    let components = src.split(separator: "\n").map { String($0) }
    return components[Random.integer(min: 0, max: components.count-1)]
  }

  static func image() -> UIImage? {
    let idx = Random.integer(min: 0, max: 4)
    guard idx != -1 else { return nil }
    return UIImage(named: "image\(idx)")
  }

  static func avatar() -> UIImage? {
    return UIImage(named: "avatar")
  }

}
