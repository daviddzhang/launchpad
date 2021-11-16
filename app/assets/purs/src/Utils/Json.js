exports.parse_ = ({ just, nothing }) => str => {
  try {
    return just(JSON.parse(str))
  } catch (error) {
    return nothing
  }
}

exports.stringify_ = JSON.stringify
