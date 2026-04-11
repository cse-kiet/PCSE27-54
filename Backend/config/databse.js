const mongoose = require('mongoose')

connectDb = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URL)
        console.log('DB connected Successfully')
    } 
    catch (error) {
        console.log("error while connecting with DB")
        console.error(error)
        process.exit(1)
    }
}

module.exports = connectDb