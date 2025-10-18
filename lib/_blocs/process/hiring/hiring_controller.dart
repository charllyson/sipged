// ===============================
// 📂 lib/_controllers/contracts/hiring_controller.dart
// ===============================

import 'package:flutter/material.dart';

/// Controlador dedicado às abas do processo de contratação pública (hiring)
class HiringController extends ChangeNotifier {
  // ----------------- Planejamento Inicial -----------------
  final TextEditingController justificativaDemandaCtrl = TextEditingController();
  final TextEditingController tipoContratacaoCtrl = TextEditingController();

  // ----------------- ETP -----------------------------------
  final TextEditingController etpJustificativaCtrl = TextEditingController();
  final TextEditingController etpDescricaoSolucaoCtrl = TextEditingController();

  // ----------------- Termo de Referência -------------------
  final TextEditingController trObjetoCtrl = TextEditingController();
  final TextEditingController trJustificativaCtrl = TextEditingController();

  // ----------------- Autorização ---------------------------
  final TextEditingController autorizacaoResponsavelCtrl = TextEditingController();
  final TextEditingController autorizacaoMotivoCtrl = TextEditingController();

  // ----------------- Comunicação Oficial -------------------
  final TextEditingController numeroOficioCtrl = TextEditingController();
  final TextEditingController destinatarioOficioCtrl = TextEditingController();
  DateTime? dataOficio;

  // ----------------- Resposta Fornecedor/Gestor ------------
  final TextEditingController respostaFornecedorCtrl = TextEditingController();

  // ----------------- Vantajosidade e Dotação --------------
  final TextEditingController vantajosidadeCtrl = TextEditingController();
  final TextEditingController dotacaoOrcamentariaCtrl = TextEditingController();

  // ----------------- Contrato e Jurídico -------------------
  final TextEditingController numeroProcessoJuridicoCtrl = TextEditingController();
  final TextEditingController parecerJuridicoCtrl = TextEditingController();
  DateTime? dataManifestacaoJuridica;

  // ----------------- Publicações ---------------------------
  final TextEditingController localPublicacaoCtrl = TextEditingController();
  DateTime? dataPublicacaoExtrato;

  // ----------------- Encerramento e Apostilas -------------
  final TextEditingController observacoesFinaisCtrl = TextEditingController();
  DateTime? dataEncerramento;

  @override
  void dispose() {
    justificativaDemandaCtrl.dispose();
    tipoContratacaoCtrl.dispose();

    etpJustificativaCtrl.dispose();
    etpDescricaoSolucaoCtrl.dispose();

    trObjetoCtrl.dispose();
    trJustificativaCtrl.dispose();

    autorizacaoResponsavelCtrl.dispose();
    autorizacaoMotivoCtrl.dispose();

    numeroOficioCtrl.dispose();
    destinatarioOficioCtrl.dispose();

    respostaFornecedorCtrl.dispose();

    vantajosidadeCtrl.dispose();
    dotacaoOrcamentariaCtrl.dispose();

    numeroProcessoJuridicoCtrl.dispose();
    parecerJuridicoCtrl.dispose();

    localPublicacaoCtrl.dispose();
    observacoesFinaisCtrl.dispose();

    super.dispose();
  }
}
