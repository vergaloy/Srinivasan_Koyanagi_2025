library(glmnet)
library(readxl)
source("align_hist.R")
library(zoo)
library(ggplot2)

# Define functions

# This function is used to calculate the moving average of a vector in a
# circular way
circular_ma <- function(k, window) {
    k <- as.matrix(k)
    n <- nrow(k)
    out <- matrix(nrow = n, ncol = ncol(k)) # Initialize the output matrix
    # Extend the vector by adding elements from the start to the end and vice versa
    for (i in 1:ncol(k)) {
        v <- k[, i]
        v_extended <- c(v[(n - window + 2):n], v, v[1:window])
        # Calculate the moving average on the extended vector
        ma <- rollmean(v_extended, window)
        # Return the middle part that corresponds to the original vector
        out[, i] <- ma[(window):(n + window - 1)] # Add the missing closing parenthesis
    }
    return(out)
}

# This function is used to calculate the effect of each predictor on the response variable
get_effects <- function(X, Y, E, intercept) {
    cv_fit <- cv.glmnet(X, Y, alpha = 0, nfolds = 10, family = "gaussian", intercept = FALSE)

    predictions <- vector("numeric", length(Y))

    for (i in seq_len(ncol(X))) {
        if (i == 1) {
            Ec <- E
        } else {
            Ec <- circ_shift(E, i - 1)
        }
        predictions[i] <- predict(cv_fit, newx = Ec, s = cv_fit$lambda.min)
    }

    # return(list(predicted_values, residuals))
    return(predictions + intercept)
}

# This function performs a circular shift on a matrix
# This function performs a circular shift on a matrix
circ_shift <- function(inv, shift_amount = 0) {
    n <- length(inv)
    shift_amount <- shift_amount %% n
    if (shift_amount == 0) {
        return(inv)
    } else {
        if (shift_amount > 0) {
            return(c(inv[(n - shift_amount + 1):n], inv[1:(n - shift_amount)]))
        } else {
            return(c(inv[-(1:(-shift_amount))], inv[1:(-shift_amount)]))
        }
    }
}

# Main code
Ridge_regression <- function(data, Ftype = "Context") {
    if (Ftype == "Context") {
        vname <- "FreezingContext"
        Yname <- "YorkContext"
    } else {
        vname <- "FreezingTone"
        Yname <- "YorkTone"
    }

    lab <- as.matrix(colnames(data[7:ncol(data)]))

    # Get predictors
    X <- as.matrix(sapply(data[, 7:ncol(data)], as.numeric))
    colnames(X) <- NULL
    X <- as.matrix(X)
    # X_norm <- sweep(X, 2, sapply(data$episodeLengthSec, as.numeric), "/")
    X_norm <- X / apply(X, 1, sum)
    # Get response freezing

    york <- data[[Yname]]
    york <- york[!is.na(york)]
    Y <- sapply(data[[vname]], as.numeric) - mean(york)

    aligned_histograms <- align_histograms_iteratively(X_norm) # Align histograms

    Rm <- colMeans(aligned_histograms)

    RMc <- circular_ma(Rm, 5)

    n <- which.max(RMc) - 1

    RMc_shifted <- t(c(RMc[-(1:n)], RMc[1:n]))


    # Number of bootstrap samples
    n_boot <- 1000

    # Matrix to store the bootstrap coefficients
    boot_coefs <- array(NA, dim = c(ncol(X), n_boot))

    # Perform the bootstrap
    set.seed(123) # for reproducibility
    for (i in 1:n_boot) {
        print(i)
        # Sample the rows with replacement
        idx <- sample(nrow(X), replace = TRUE)
        # Store the coefficients
        boot_coefs[, i] <- get_effects(X_norm[idx, ], Y[idx], RMc_shifted, mean(york))
    }

    # Assuming 'boot_coefs' is your 3x36 matrix
    means <- apply(boot_coefs, 1, mean)
    sem <- apply(boot_coefs, 1, function(x) sd(x))

    # Assuming 'boot_coefs' is your 3x36 matrix and MainEffect is a vector of the same length
    df <- data.frame(lab, means, upper_sem = means + sem, lower_sem = means - sem)

    # Create the plot
    p <- ggplot(df, aes(x = as.numeric(lab), y = means)) +
        geom_line(aes(group = 1)) +
        geom_ribbon(aes(ymin = lower_sem, ymax = upper_sem, group = 1), alpha = 0.2, fill = "blue") +
        geom_line(aes(y = means), color = "blue") +
        scale_x_continuous(breaks = seq(-180, 180, by = 45)) +
        labs(x = "Phase", y = "Predicted Freezing", title = Ftype)

    print(p)
    return(df)
}
