const express = require("express");
const http = require("http");
const socketIo = require("socket.io");

const port = process.env.PORT || 5000;

const app = express();

const server = http.createServer(app);

app.use("/", (req, res) => {
    res.send("Site is live!");
})

const io = socketIo(server, {
    cors: {}
});

io.on("connection", function (socket) {
    //console.log("New client connected");

    // console.log(io.sockets.adapter.rooms);
    // console.log(socket.id);

    socket.on("join", (roomId) => {
        socket.join(roomId);
    })

    socket.on("newConnect", (roomId, callback) => {
        //console.log(callback);
        //console.log(io.sockets.adapter.rooms);
        let socketIds = Object.keys(io.sockets.adapter.rooms[roomId].sockets).filter(id => id !== socket.id);
        // console.log(socketIds);
        // console.log(socket.id);
        callback({ originId: socket.id, destinationIds: socketIds });
    })

    socket.on("createOffer", (data) => {
        var socketId = {
            originId: data.socketId.destinationId,
            destinationId: data.socketId.originId
        }
        //console.log(session);
        io.to(data.socketId.destinationId).emit("receiveOffer", { session: data.session, socketId: socketId });
        //socket.broadcast.emit("receiveOffer", { session: data.session, socketId: socketId });
    })

    socket.on("createAnswer", (data) => {
        var socketId = {
            originId: data.socketId.destinationId,
            destinationId: data.socketId.originId
        }
        io.to(data.socketId.destinationId).emit("receiveAnswer", { session: data.session, socketId: socketId });
    })

    socket.on("sendCandidate", (data) => {
        var socketId = {
            originId: data.socketId.destinationId,
            destinationId: data.socketId.originId
        }
        //console.log(data);
        io.to(data.socketId.destinationId).emit("receiveCandidate", { candidate: data.candidate, socketId: socketId });
    })
    socket.on("disconnect", () => {
        socket.broadcast.emit("userDisconnected", socket.id);
        //console.log("Client disconnected", socket.id);
    })
})

server.listen(port, () => console.log(`Listening on port ${port}`));