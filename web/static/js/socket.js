import {Presence, Socket} from "phoenix"

// Visual stuff

let usersInStoryContainer = document.querySelector("#users-in-story")

let appendUserInStory = (username) => {
  let item = document.createElement("li")

  if (username === window.username) {
    item.innerText = `${username} (you)`
    item.setAttribute("class", "collection-item current-user")
  } else {
    item.innerText = username
    item.setAttribute("class", "collection-item")
  }

  usersInStoryContainer.appendChild(item)
}

let removeUserItem = (username) => {
  usersInStoryContainer.childNodes.forEach(item => {
    if (item.innerText == username) {
      usersInStoryContainer.removeChild(item)
    }
  })
}

let displayOnlineUsers = (users) => {
  usersInStoryContainer.innerHTML = ""

  let header = document.createElement("li")
  header.innerText = "users in this story"
  header.setAttribute("class", "collection-header")
  usersInStoryContainer.appendChild(header)

  users.forEach(({username: username}) => {
    appendUserInStory(username)
  })
}

let displayCurrentWriter = (username) => {
  let currentWriterContainer = document.querySelector("#current-writer > span.username")
  currentWriterContainer.innerText = username
}

let appendWordToStory = (wordsContainer, {word: word, author: author}) => {
  let wordSpan = document.createElement("span")
  wordSpan.innerText = word
  wordSpan.setAttribute("class", "word")

  let authorSpan = document.createElement("span")
  authorSpan.innerText = author
  authorSpan.setAttribute("class", "author")

  let wordItem = document.createElement("li")
  wordItem.appendChild(wordSpan)
  wordItem.appendChild(authorSpan)

  wordsContainer.appendChild(wordItem)
}

let displayStoryWords = (words) => {
  let wordsContainer = document.querySelector("#words")
  words.forEach(word => { appendWordToStory(wordsContainer, word) })
}

// Presence handling

let listPresencesBy = (user, {metas: metas}) => {
  return {username: user};
}

let onUserJoin = (id, current, newPresence) => {
  console.log("onUserJoin", {id, current, newPresence})
  appendUserInStory(id)
}

let onUserLeave = (id, current, leftPresence) => {
  console.log("onUserLeave", {id, current, leftPresence})
  removeUserItem(id)
}

// Channel interaction

let socket = new Socket("/socket", {params: {username: window.username}})

socket.connect()

let storyChannelSetup = (sock, currentStorySlug) => {
  let storyChannel = sock.channel(`story:${currentStorySlug}`, {})
  let presences = {}
  let countdownTimeout = undefined
  let wordInput = document.querySelector("#word-input")

  storyChannel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

  storyChannel.on("after_join", params => {
    console.log("Received after_join with presence state and story", params)
    presences = Presence.syncState(presences, params.presence_state)
    displayOnlineUsers(Presence.list(presences, listPresencesBy))
    displayStoryWords(params.story.words)
    displayCurrentWriter(params.story.elected_writer)
  })

  storyChannel.on("presence_diff", diff => {
    console.log("Received presence_diff with diff", diff)
    presences = Presence.syncDiff(presences, diff, onUserJoin, onUserLeave)
  })

  storyChannel.on("elected_next_writer", ({elected: username, previous: previous}) => {
    console.log("Received elected_next_writer with current and previous", username, previous)
    let countdownContainer = document.querySelector("#countdown")

    clearTimeout(countdownTimeout)

    countdownContainer.innerText = "8.0"

    function countdown() {
      let seconds = parseFloat(countdownContainer.innerText, 10)

      if (seconds <= 0.0) {
        return
      }

      seconds = seconds - 0.05 // 10 ms
      countdownContainer.innerText = seconds.toFixed(2)
      countdownTimeout = setTimeout(countdown, 50)
    }

    countdown();

    if (previous === window.username) {
      if (wordInput.value === "") {
        Materialize.toast("What a missed opportunity!", 2000)
      } else {
        storyChannel.push("new_word", {
          new_word: wordInput.value,
          author: window.username,
        })
        wordInput.value = ""
      }
    }

    if (username === window.username) {
      wordInput.removeAttribute("disabled")
      displayCurrentWriter(`${username} (you!)`)
      $(document.body).addClass("is-current-writer")
    } else {
      wordInput.setAttribute("disabled", "")
      displayCurrentWriter(username)
      $(document.body).removeClass("is-current-writer")
    }
  })

  storyChannel.on("appended_word", ({appended_word: word}) => {
    let wordsContainer = document.querySelector("#words")
    appendWordToStory(wordsContainer, word)
  })

  wordInput.addEventListener("keypress", (event) => {
    if (event.keyCode === 32 /* space */) {
      event.preventDefault()
      Materialize.toast("One word at a time, no spaces!", 3000)
    } else if (event.keyCode === 13 /* return */) {
      event.preventDefault()
      Materialize.toast("The word will be sent at the end of the turn", 3500)
    }
  })
}

if (window.currentStorySlug) {
  storyChannelSetup(socket, window.currentStorySlug)
}

export default socket
