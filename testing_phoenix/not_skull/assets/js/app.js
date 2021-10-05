// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import deps with the dep name or local files with a relative path, for example:
//
//     import {Socket} from "phoenix"
//     import socket from "./socket"
//
import "phoenix_html"
import { Socket } from "phoenix"
import NProgress from "nprogress"
import { LiveSocket } from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, { params: { _csrf_token: csrfToken } })

let userJwt = document.querySelector("meta[name='user-jwt']").getAttribute("content")

// Show progress bar on live navigation and form submits
window.addEventListener("phx:page-loading-start", info => NProgress.start())
window.addEventListener("phx:page-loading-stop", info => NProgress.done())

liveSocket.connect()
    // expose liveSocket on window for web console debug logs and latency simulation:
    >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket

// Connect at the socket path in "lib/web/endpoint.ex":
let socket = new Socket("/socket", { params: { token: userJwt } })
socket.connect()

// Now that you are connected, you can join channels with a topic:
let channel = socket.channel("lobby:lobby", {})

channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.error("Unable to join", resp) })

channel.on("new_game_created", payload => {
    let activeGamesList = document.getElementById("active-games")

    let liElement = document.createElement("li")
    liElement.innerHTML = `<a href="/game?game_id=${payload.game_id}">${payload.game_id}</a>`

    activeGamesList.appendChild(liElement)
})

// To push to a channel:
//
//   channel.push("some_message", {some: "payload"})
//
// To handle events:
//
//   channel.on("message", message => {})
//

export default socket
