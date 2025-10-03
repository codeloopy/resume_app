# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end
# db/seeds.rb
require 'faker'

Article.destroy_all

Article.create!(
  [
    {
      image: "https://via.placeholder.com/340x192",
      category: "Interview Prep",
      read_time: "3",
      title: "10 Remote Interview Tips That Actually Work",
      body: <<~BODY,
        Remote interviews are here to stay, and mastering them is crucial for landing your dream job. Here are 10 tips to help you shine.

        **1. Test Your Tech**
        Before the interview, ensure your internet connection, webcam, and microphone are working perfectly. Do a test call with a friend.

        **2. Choose a Quiet, Clutter-Free Space**
        Find a well-lit area with a neutral background. Minimize distractions and inform housemates you'll be busy.

        **3. Dress Professionally**
        Even if it's a remote interview, dress as you would for an in-person one. It helps you feel more confident.

        **4. Have Water Nearby**
        Keep a glass of water handy in case your throat gets dry.

        **5. Research the Company & Role**
        Know their mission, recent projects, and what the role entails. Tailor your answers to their needs.

        **6. Prepare Questions for Them**
        Asking thoughtful questions shows your engagement and interest.

        **7. Practice Your Answers**
        Rehearse common interview questions. Record yourself to identify areas for improvement.

        **8. Make Eye Contact (with the camera)**
        It might feel unnatural, but looking at your webcam simulates eye contact with your interviewer.

        **9. Body Language Matters**
        Sit upright, smile, and nod occasionally to show you're engaged.

        **10. Send a Thank-You Note**
        Follow up with a personalized thank-you email within 24 hours.

        Mastering these tips will help you ace your next remote interview and make a lasting impression.
      BODY
      author: "Mike Rodriguez",
      author_initials: "MR",
      published_at: "Dec 15, 2024",
      featured: false,
      color: "blue",
      icon: "handshake"
    },
    {
      image: "https://via.placeholder.com/340x192",
      category: "Career Growth",
      read_time: "7",
      title: "How to Negotiate Your Salary Like a Pro",
      body: <<~BODY,
        Negotiating salary can feel intimidating, but the truth is, employers expect it. Failing to negotiate could mean leaving thousands of dollars on the table over your career. Here’s how to approach it like a professional.

        **Do Your Homework**
        Research industry benchmarks for your role, location, and experience. Tools like Glassdoor and Payscale can help.

        **Know Your Value**
        Document your achievements—cost savings, revenue generated, projects delivered. Numbers speak louder than adjectives.

        **Practice Your Script**
        Instead of winging it, practice responses like:
        - “Based on my research and experience, I was expecting something closer to X.”
        - “Is there flexibility in the offer?”

        **Timing Matters**
        Bring up salary only after an offer has been made or when asked directly about expectations.

        **Non-Salary Benefits**
        Sometimes budget is fixed. Negotiate perks like flexible hours, remote work, or extra vacation days.

        **Confidence is Key**
        Remember: negotiation isn’t conflict—it’s collaboration. Employers want you happy and motivated.

        A well-planned salary negotiation can set the tone for your entire career. Approach it with preparation, confidence, and respect, and you’ll maximize both your income and professional reputation.
      BODY
      author: "Anna Lee",
      author_initials: "AL",
      published_at: "Dec 12, 2024",
      featured: false,
      color: "green",
      icon: "chart-line"
    },
    {
      image: "https://via.placeholder.com/340x192",
      category: "Job Search",
      read_time: "4",
      title: "LinkedIn Profile Optimization: Get Recruiters to Notice You",
      body: <<~BODY,
        Your LinkedIn profile is often the first impression recruiters have of you. A strong profile can double your chances of landing interviews.

        **Headline That Pops**
        Don’t just list your job title. Use the headline to highlight what you do best: “Full Stack Developer | Specializing in Scalable Rails Apps.”

        **Professional Photo**
        Profiles with photos get up to 21× more views. Choose a clear, professional image with good lighting.

        **Compelling Summary**
        Write a short, engaging paragraph about your skills, passions, and what you’re looking for. Keep it personable yet professional.

        **Showcase Achievements**
        Use bullet points in your experience section to highlight measurable results: “Improved page load speed by 45%.”

        **Skills & Endorsements**
        Add relevant skills, and ask colleagues to endorse them.

        **Engage on the Platform**
        Post, comment, and share articles. Recruiters prefer active profiles.

        An optimized LinkedIn profile isn’t just a résumé online—it’s your professional brand. Invest the time to update yours, and you’ll see the recruiter messages start rolling in.
      BODY
      author: "David Chen",
      author_initials: "DC",
      published_at: "Dec 10, 2024",
      featured: false,
      color: "purple",
      icon: "search"
    },
    {
      image: "https://via.placeholder.com/340x192",
      category: "Resume Tips",
      read_time: "6",
      title: "Resume Keywords: The Secret to Getting Past ATS",
      body: <<~BODY,
        Applicant Tracking Systems (ATS) filter résumés before a human even sees them. If your résumé lacks the right keywords, it may never reach the hiring manager.

        **Why Keywords Matter**
        ATS scans for job-specific terms like “Agile,” “SQL,” or “budget forecasting.” Missing these terms can disqualify you instantly.

        **Find the Right Keywords**
        Study job descriptions carefully. Highlight repeating skills and phrases—that’s what the ATS is looking for.

        **Natural Integration**
        Don’t just stuff keywords. Weave them naturally into your experience:
        - Instead of: “Worked on databases.”
        - Try: “Optimized SQL databases to improve query speed by 30%.”

        **Use Variations**
        If one job ad says “customer support” and another says “client service,” include both.

        **Balance Humans and Bots**
        While ATS is important, remember that a recruiter will eventually read your résumé. Keep it clean, professional, and easy to skim.

        Resume keywords are the bridge between you and your next opportunity. Use them strategically to ensure your résumé gets past the system and into human hands.
      BODY
      author: "Sarah Johnson",
      author_initials: "SJ",
      published_at: "Dec 8, 2024",
      featured: false,
      color: "red",
      icon: "edit"
    },
    {
      image: "https://via.placeholder.com/340x192",
      category: "Career Growth",
      read_time: "5",
      title: "Making a Career Change: A Step-by-Step Guide",
      body: <<~BODY,
        Thinking about switching careers? You’re not alone. Millions of professionals pivot into new fields every year. With the right approach, you don’t need to start from zero.

        **Step 1: Identify Transferable Skills**
        Look at what you already do well—project management, communication, coding, problem-solving—and match them to your target field.

        **Step 2: Upskill Strategically**
        Take online courses, certifications, or part-time projects to fill skill gaps.

        **Step 3: Network in Your New Industry**
        Attend events, join LinkedIn groups, and connect with professionals already working in your desired field.

        **Step 4: Start Small**
        Freelance, volunteer, or take on side projects to gain real-world experience.

        **Step 5: Rebrand Your Resume**
        Highlight transferable skills and show enthusiasm for the new industry.

        Career changes are challenging but rewarding. With preparation and persistence, you can transition smoothly into a field that excites you.
      BODY
      author: "Tom Wilson",
      author_initials: "TW",
      published_at: "Dec 5, 2024",
      featured: false,
      color: "yellow",
      icon: "lightbulb"
    },
    {
      image: "https://via.placeholder.com/340x192",
      category: "Job Search",
      read_time: "8",
      title: "Networking That Actually Works: Build Meaningful Connections",
      body: <<~BODY,
        Networking often gets a bad rap—awkward events, forced conversations, and business card exchanges that go nowhere. But real networking is about building authentic, long-lasting professional relationships.

        **Shift Your Mindset**
        Networking isn’t about asking for favors; it’s about offering value and finding mutual interests.

        **Be Curious**
        Ask open-ended questions like “What’s the most exciting project you’re working on?” People love to share their stories.

        **Give Before You Take**
        Offer an introduction, share a resource, or help with a small challenge before expecting anything in return.

        **Follow Up Thoughtfully**
        Send a LinkedIn request with a personal note, or follow up with an email mentioning something from your conversation.

        **Leverage Online Communities**
        Twitter, Slack groups, and niche forums can be just as valuable as in-person events.

        **Play the Long Game**
        The best networking relationships often pay off years later. Stay connected even when you don’t “need” something.

        Networking doesn’t have to feel sleazy. By focusing on genuine connections and long-term value, you’ll build a professional network that truly supports your career.
      BODY
      author: "Emily Martinez",
      author_initials: "EM",
      published_at: "Dec 3, 2024",
      featured: false,
      color: "indigo",
      icon: "network-wired"
    }
  ]
)

# --- Faker-Generated Dummy Blog Posts ---
20.times do
  author_name = Faker::Name.name
  initials = author_name.split.map { |n| n[0] }.join.upcase

  Article.create!(
    image: "https://via.placeholder.com/340x192",
    category: [ 'Interview Prep', 'Career Growth', 'Job Search', 'Resume Tips', 'Career Change', 'Networking' ].sample,
    read_time: "#{rand(3..10)}",
    title: Faker::Marketing.buzzwords.titleize,
    body: Faker::Lorem.paragraphs(number: 5).join("\n\n"),
    author: author_name,
    author_initials: initials,
    published_at: Faker::Date.backward(days: 60).strftime("%b %d, %Y"),
    featured: false,
    color: %w[blue green purple red yellow indigo].sample,
    icon: %w[handshake chart-line search edit lightbulb network-wired].sample
  )
end

puts "Seeded #{Article.count} articles (6 curated + 20 faker = #{6 + 20})!"
