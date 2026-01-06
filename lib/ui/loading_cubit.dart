import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_iot_application/services/helper.dart';
part 'loading_state.dart';

class LoadingCubit extends Cubit<LoadingState> {
  LoadingCubit() : super(LoadingInitial());

  void showLoading(BuildContext context, String message, bool isDismissible,
  {Color? colorPrimary}) {
    showProgress(
        context, message, isDismissible, colorPrimary ?? Color(0xFF3E66C5));
  }

  void hideLoading() {
    hideProgress();
  }
}
